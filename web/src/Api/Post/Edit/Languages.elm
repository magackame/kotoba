module Api.Post.Edit.Languages exposing (Request, request)

import Api
import Api.Language as Language exposing (Language)
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { postContentId : Int
    , query : String
    }


request : Request -> (Result Http.Error (List Language) -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/post/edit/languages"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse <| D.list Language.decoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "post_content_id", E.int req.postContentId )
        , ( "query", E.string req.query )
        ]
