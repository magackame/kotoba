module Status exposing (Status(..))


type Status a e
    = Idle
    | Loading
    | Success a
    | Error e
