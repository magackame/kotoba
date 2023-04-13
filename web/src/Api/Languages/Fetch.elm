module Api.Languages.Fetch exposing (Request, request)

import Api
import Api.Language as Language exposing (Language)
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { query : String
    }


request : Request -> (Result Http.Error (List Language) -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/languages/fetch"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse <| D.list Language.decoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "query", E.string req.query )
        ]
