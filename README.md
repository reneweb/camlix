# camlix

Camlix is a simple circuit breaker library for ocaml

## Usage

### Simple command
```ocaml
open Core
open Camlix

exception TooLarge of string

let double_if_lt_ten n = 
    if n > 10 then
        Error (TooLarge "Larger 10")
    else
        Ok (n * 2)
;;

(* Define a simple circuit breaker *)
let cmd = Command.create (Config.create ()) ~f:double_if_lt_ten;;

(* and run it with an example input *)
let result = Command.run cmd 10;;
assert ((Result.ok_exn result) = 20)
```

### Command with fallback
```ocaml
open Core
open Camlix

exception TooLarge of string

let double_if_lt_ten n = 
    if n > 10 then
        Error (TooLarge "Larger 10")
    else
        Ok (n * 2)
;;

(* Define a circuit breaker command with a fallback function *)
let cmd = Command.create_with_fallback (Config.create ()) ~f:double_if_lt_ten ~fb:(fun _ -> 4);;

(* and run it with an example input *)
let result = Command.run cmd 11;;
assert ((Result.ok_exn result) = 4)
```

### Command with custom configuration
```ocaml
open Core
open Camlix

let config = { (Config.create ()) with
    error_threshold            = 10;
    error_threshold_percentage = 50;
    buckets_in_window          = 10;
    bucket_size_in_ms          = 1000;
    circuit_open_ms            = 5000;
}

exception TooLarge of string

let double_if_lt_ten n = 
    if n > 10 then
        Error (TooLarge "Larger 10")
    else
        Ok (n * 2)
;;

(* Define a circuit breaker command with custom configuration *)
let cmd = Command.create_with_fallback config ~f:double_if_lt_ten ~fb:(fun _ -> 4);;

(* and run it with an example input *)
let result = Command.run cmd 10;;
assert ((Result.ok_exn result) = 20)
```

### Command with custom rejection error
By default the error type is `exn` as an `ExecutionRejected` exception is used when the circuit is open.
If you want a different error type you can use the `run_with_custom_rejection` function:

```ocaml
open Core
open Camlix

let double_if_lt_ten n = 
    if n > 10 then
        Error "Larger 10"
    else
        Ok (n * 2)
;;

(* Define a simple circuit breaker *)
let cmd = Command.create (Config.create ()) ~f:double_if_lt_ten;;

(* and run it with an example input providing a custom rejection *)
let result = Command.run_with_custom_rejection cmd 10 "Just using a string here";;
assert ((Result.ok_or_failwith result) = 20)
```

## Configuration

`circuit_open_ms` - Time in ms commands are rejected after the circuit opened - Default 5000

`error_threshold` - Minimum amount of errors for the circuit to break - Default 10

`error_threshold_percentage` - Minimum error percentage for the circuit to break - Default 50

`buckets_in_window` - Rolling window to track success/error calls, this property defines the amount of buckets in a window (buckets_in_window * bucket_size_in_ms is the overall length in ms of the window) - Default 10

`bucket_size_in_ms` - This property defines the ms a bucket is long, i.e. each x ms a new bucket will be created (buckets_in_window * bucket_size_in_ms is the overall length in ms of the window) - Default 1000

`circuit_breaker_enabled` - Defines if the circuit breaker is enabled or not - Default true