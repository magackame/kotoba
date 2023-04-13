module Api.Post.Translations exposing (Request, request)


import Api
import Api.Translation as Translation exposing (Translation)
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { postId : Int
    }


type alias Response = List Translation


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/post/translations"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse <| D.list Translation.decoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "post_id", E.int req.postId )
        ]
