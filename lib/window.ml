open Core
open Config

module Point = struct
    type t = Success | Failure [@@deriving equal]
end

module Bucket = struct
    type t = {
        points    : Point.t Queue.t;
        timestamp : Time.t;
    }

    let create () = { points = Queue.create (); timestamp = Time.now () }
    let create_with_timestamp timestamp = { points = Queue.create (); timestamp = timestamp }
end

module Window = struct
    type t = {
        (* Queue structure holding the window's buckets *)
        buckets: Bucket.t Deque.t;

        (* Period during which a single bucket is valid *)
        bucket_ms: Time.Span.t;

        (* Maximum number of buckets in a window *)
        buckets_nr: int;

        (* Total size of all buckets in a window *)
        window_size: Time.Span.t;
    }

    let create (cfg: Config.t) = 
        let bucket_ms = Time.Span.of_ms (float_of_int cfg.bucket_size_in_ms) in
        let window_size = Time.Span.of_ms ((float_of_int cfg.bucket_size_in_ms) *. (float_of_int cfg.buckets_in_window))  in
        
        { bucket_ms = bucket_ms; window_size = window_size; buckets = Deque.create (); buckets_nr = cfg.buckets_in_window }
    ;;

    let clear_window w = 
        Deque.clear w.buckets
    ;;

    let get_points w = 
        let threshold = Time.sub (Time.now ()) w.window_size in
        w.buckets 
            |> Deque.to_list 
            |> List.filter ~f:(fun (bucket: Bucket.t) -> Time.(>) bucket.timestamp threshold)
            |> List.concat_map ~f:(fun (bucket: Bucket.t) -> Queue.to_list bucket.points)
    ;;

    let update_window_returning_latest_bucket w = 
        let now = Time.now () in
        let latest_threshold = w.buckets
            |> Deque.peek_back 
            |> Option.map ~f:(fun (bucket: Bucket.t) -> Time.add bucket.timestamp w.bucket_ms) in

        match latest_threshold with 
            | Some threshold -> begin
                    if Time.(>) threshold now then
                        Deque.peek_back_exn w.buckets
                    else begin
                        let new_bucket = Bucket.create_with_timestamp threshold in
                        Deque.enqueue_back w.buckets new_bucket;

                        if Deque.length w.buckets > w.buckets_nr then
                            ignore ((Deque.dequeue_front w.buckets) : Bucket.t Option.t);

                        Deque.peek_back_exn w.buckets
                    end
                end
            | None -> 
                let first_bucket = Bucket.create () in
                Deque.enqueue_back w.buckets first_bucket;
                Deque.peek_back_exn w.buckets
    ;;

    let add_point w p = 
        let current_bucket = update_window_returning_latest_bucket w in
        Queue.enqueue current_bucket.points p
    ;;
end
