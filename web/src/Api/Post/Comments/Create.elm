module Api.Post.Comments.Create exposing (Request, Response(..), request)

import Api exposing (encodeMaybe)
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { token : String
    , postContentId : Int
    , replyTo : Maybe Int
    , content : String
    }


type Response
    = Unauthorized
    | Success


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/post/comments/create"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "token", E.string req.token )
        , ( "post_content_id", E.int req.postContentId )
        , ( "reply_to", encodeMaybe E.int req.replyTo )
        , ( "content", E.string req.content )
        ]


responseDecoder : D.Decoder Response
responseDecoder =
    D.andThen
        responseInnerDecoder
        (D.field "tag" D.string)


responseInnerDecoder : String -> D.Decoder Response
responseInnerDecoder tag =
    case tag of
        "Unauthorized" ->
            D.succeed Unauthorized

        "Success" ->
            D.succeed Success

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding Post.Comments.Create.Response"
