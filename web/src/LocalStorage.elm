module LocalStorage exposing (LocalStorage, decode, getLocalStorage, setLocalStorage)

import Api exposing (encodeMaybe)
import Json.Decode as D
import Json.Encode as E
import Ports


type alias LocalStorage =
    { retoken : Maybe String
    , languageIds : List Int
    , tagIds : List Int
    }


default : LocalStorage
default =
    { retoken = Nothing
    , languageIds = [ 1 ]
    , tagIds = [ 1 ]
    }


setLocalStorage : LocalStorage -> Cmd msg
setLocalStorage localStorage =
    Ports.setLocalStorage <| encode localStorage


getLocalStorage : (LocalStorage -> msg) -> Sub msg
getLocalStorage gotLocalStorage =
    Ports.getLocalStorage (gotLocalStorage << decode)


decode : E.Value -> LocalStorage
decode json =
    Result.withDefault default <| D.decodeValue decoder json


decoder : D.Decoder LocalStorage
decoder =
    D.map3 LocalStorage
        (D.field "retoken" <| D.maybe D.string)
        (D.field "language_ids" <| D.list D.int)
        (D.field "tag_ids" <| D.list D.int)


encode : LocalStorage -> E.Value
encode localStorage =
    E.object
        [ ( "retoken", encodeMaybe E.string localStorage.retoken )
        , ( "language_ids", E.list E.int localStorage.languageIds )
        , ( "tag_ids", E.list E.int localStorage.tagIds )
        ]
