open Core
open Circuit_breaker

module Command = struct

    type ('i, 'o, 'e) t = {
        f : 'i -> ('o, 'e) Result.t;
        fb  : ('e -> 'o) Option.t;
        circuit_breaker: CircuitBreaker.t;
    }

    exception ExecutionRejected of string

    let create cfg ~f =
        {
            f = f;
            fb = None;
            circuit_breaker = CircuitBreaker.create cfg
        }
    ;;

    let create_with_fallback cfg ~f ~fb =
        {
            f = f;
            fb = Some fb;
            circuit_breaker = CircuitBreaker.create cfg
        }
    ;;

    let run_with_custom_rejection cmd param rej =
        let enabled = cmd.circuit_breaker.config.circuit_breaker_enabled in
        if enabled then begin
            let is_allowed = CircuitBreaker.check_command_allowed cmd.circuit_breaker in
            if is_allowed then begin
                let result = cmd.f param in
                CircuitBreaker.register_result cmd.circuit_breaker.circuit_breaker_stats result;
                match result with
                 | Ok res -> Ok res
                 | Error err -> begin
                    match cmd.fb with
                        | Some fb -> Ok (fb err)
                        | None -> Error err
                    end
            end
            else begin
                match cmd.fb with
                 | Some fb -> Ok (fb rej)
                 | None -> Error rej
            end
        end else begin
            cmd.f param
        end
    ;;

    let run cmd param = run_with_custom_rejection cmd param (ExecutionRejected "Execution rejected")
end