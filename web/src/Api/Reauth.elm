module Api.Reauth exposing (Request, request)

import Api
import Api.SignIn exposing (User, responseDecoder)
import Http
import Json.Encode as E


type alias Request =
    { retoken : String
    }


type alias Response =
    User


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/reauth"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "retoken", E.string req.retoken )
        ]
