module Api.User.Comments exposing (Request, Response, request)

import Api
import Api.Comment as Comment exposing (Comment)
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { userId : Int
    , query : String
    , limit : Int
    , offset : Int
    }


type alias Response =
    List Comment


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/user/comments"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse <| D.list Comment.decoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "user_id", E.int req.userId )
        , ( "query", E.string req.query )
        , ( "limit", E.int req.limit )
        , ( "offset", E.int req.offset )
        ]
