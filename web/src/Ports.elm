port module Ports exposing (endOfPageReached, getLocalStorage, retry, scrollTo, setLocalStorage, triggerRetry)

import Json.Encode as E


port setLocalStorage : E.Value -> Cmd msg


port getLocalStorage : (E.Value -> msg) -> Sub msg


port scrollTo : String -> Cmd msg


port endOfPageReached : (() -> msg) -> Sub msg


port triggerRetry : () -> Cmd msg


port retry : (() -> msg) -> Sub msg
