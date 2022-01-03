open Core
open Camlix

exception TestError of string

let runs_command () = Alcotest.(check int) "returns ok result" 5 (
    let test_fun () = Ok 5 in
    let test_cmd = Command.create (Config.create ()) ~f:test_fun in
    () |> Command.run test_cmd |> Result.ok_exn
);;

let runs_command_multiple_times () = Alcotest.(check (list int)) "returns ok result multiple times" [5; 5; 5; 5; 5] (
    let test_fun () = Ok 5 in
    let test_cmd = Command.create (Config.create ()) ~f:test_fun in
    List.init 5 ~f:(fun _ -> () |> Command.run test_cmd |> Result.ok_exn)
);;

let runs_command_with_param () = Alcotest.(check (result int string)) "returns ok result" (Ok 5) (
    let test_fun x = Ok x in
    let test_cmd = Command.create (Config.create ()) ~f:test_fun in
    Command.run_with_custom_rejection test_cmd 5 "CmdRejected"
);;

let rejects_command_if_circuit_open () =  Alcotest.(check (list (result int string))) 
    "returns multiple error results" [Error "CmdRejected"; Error "CmdError"; Error "CmdError"; Error "CmdError"; Error "CmdError"; Error "CmdError"] 
(
    let test_fun _ = Error "CmdError" in
    let test_cmd = Command.create { (Config.create ()) with error_threshold = 5 } ~f:test_fun in
    List.init 6 ~f:(fun _ -> Command.run_with_custom_rejection test_cmd () "CmdRejected")
);;

let returns_fallback_if_err_result_returned () =  Alcotest.(check (result int string)) "returns ok result" (Ok 5) (
    let test_fun _ = Error "CmdError" in
    let test_fb _ = 5 in
    let test_cmd = Command.create_with_fallback (Config.create ()) ~f:test_fun ~fb:test_fb in
    Command.run_with_custom_rejection test_cmd 5 "CmdRejected"
);;

let returns_fallback_if_circuit_open () =  Alcotest.(check (list (result int string))) 
    "returns fallback results" [Ok 5; Ok 5; Ok 5; Ok 5; Ok 5; Ok 5]
(
    let test_fun _ = Error "CmdError" in
    let test_fb _ = 5 in
    let test_cmd = Command.create_with_fallback { (Config.create ()) with error_threshold = 5 } ~f:test_fun ~fb:test_fb in
    List.init 6 ~f:(fun _ -> Command.run_with_custom_rejection test_cmd () "CmdRejected")
);;

let handles_lots_of_calls () =  Alcotest.(check (list (result int string))) "returns lots of ok results" (List.init 10000 ~f:(fun i -> Ok i)) (
    let test_fun i = Ok i in
    let test_cmd = Command.create (Config.create ()) ~f:test_fun in
    List.init 10000 ~f:(fun i -> Command.run_with_custom_rejection test_cmd i "CmdRejected")
);;

let () =
  let open Alcotest in
  run "Command" [
      "runs_command", [ test_case "Run simple command" `Quick runs_command  ];
      "runs_command_multiple_times", [ test_case "Run simple command multiple times" `Quick runs_command_multiple_times  ];
      "runs_command_with_param", [ test_case "Run command with param" `Quick runs_command_with_param  ];
      "rejects_command_if_circuit_open", [ test_case "Reject command if circuit open" `Quick rejects_command_if_circuit_open  ];
      "returns_fallback_if_err_result_returned", [ test_case "Return fallback if error result returned" `Quick returns_fallback_if_err_result_returned  ];
      "returns_fallback_if_circuit_open", [ test_case "Return fallback if circuit is open" `Quick returns_fallback_if_circuit_open  ];
      "handles_lots_of_calls", [ test_case "Handle lots of calls" `Quick handles_lots_of_calls  ];
    ]
