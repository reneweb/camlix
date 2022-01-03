module Config = struct

    type t = {
        error_threshold            : int;
        error_threshold_percentage : int;
        buckets_in_window          : int;
        bucket_size_in_ms          : int;
        circuit_open_ms            : int;
        circuit_breaker_enabled    : bool;
    }

    let create () =
        {
            error_threshold            = 10;
            error_threshold_percentage = 50;
            buckets_in_window          = 10;
            bucket_size_in_ms          = 1000;
            circuit_open_ms            = 5000;
            circuit_breaker_enabled    = true;
        }
    ;;
end