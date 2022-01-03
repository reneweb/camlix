open Core
open Window

module CircuitBreakerStats = struct

    type t = { window: Window.t }

    let create cfg =
        { window = Window.create cfg }
    ;;

    let add_point cbs p =
        Window.add_point cbs.window p
    ;;
        
    let clear cbs =
        Window.clear_window cbs.window
    ;;

    let success_nr cbs =
        let points = Window.get_points cbs.window in
        points |> List.filter ~f:(fun p -> Point.equal p Point.Success) |> List.length
    ;;

    let success_percentage cbs =
        let points = Window.get_points cbs.window in
        let success_nr = success_nr cbs in
        if success_nr = 0 then
            0
        else
            int_of_float ((float_of_int (success_nr) /. float_of_int (List.length points)) *. 100.)
    ;;

    let error_nr cbs =
        let points = Window.get_points cbs.window in
        points |> List.filter ~f:(fun p -> Point.equal p Point.Failure) |> List.length

    let error_percentage cbs = 
        let points = Window.get_points cbs.window in
        let error_nr = error_nr cbs in

        if error_nr = 0 then
            0
        else
            int_of_float ((float_of_int (error_nr) /. float_of_int (List.length points)) *. 100.)
    ;;
end
