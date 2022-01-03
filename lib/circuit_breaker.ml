open Core
open Window
open Circuit_breaker_stats
open Config

module CircuitBreaker = struct

    type t = {
        circuit_breaker_stats     : CircuitBreakerStats.t;
        config                    : Config.t;
        mutable circuit_open_time : Time.t Option.t;
    }

    let create cfg =
        {
            circuit_breaker_stats = CircuitBreakerStats.create cfg;
            circuit_open_time = None;
            config = cfg;
        }
    ;;

    let register_result cbs r =
        match r with
         | Ok(_) -> CircuitBreakerStats.add_point cbs Point.Success
         | Error(_) -> CircuitBreakerStats.add_point cbs Point.Failure
    ;;

    let time_to_close_circuit cb =
        cb.config.circuit_open_ms |> float_of_int |> Time.Span.of_ms |> Time.sub (Time.now ())
    ;;

    let should_close_open_circuit cb =
        match cb.circuit_open_time with
         | Some open_time -> Time.(<=) open_time (time_to_close_circuit cb)
         | None -> false
    ;;

    let should_keep_circuit_open cb =
        match cb.circuit_open_time with
         | Some open_time -> Time.(>) open_time (time_to_close_circuit cb)
         | None -> false
    ;;

    let should_open_circuit cb cbs =
        let pct_above_threshold = CircuitBreakerStats.error_percentage cbs >= cb.config.error_threshold_percentage in
        let count_above_threshold = CircuitBreakerStats.error_nr cbs >= cb.config.error_threshold in

        pct_above_threshold && count_above_threshold
    ;;

    let check_command_allowed cb =
        if should_close_open_circuit cb then begin
            cb.circuit_open_time <- None;
            true
        end else if should_keep_circuit_open cb then
            false
        else if should_open_circuit cb cb.circuit_breaker_stats then begin
            cb.circuit_open_time <- Some (Time.now ());
            CircuitBreakerStats.clear cb.circuit_breaker_stats;
            false
        end else
            true
    ;;
end