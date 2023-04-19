module Api.Post.Translations.Status exposing (Request, Response(..), request)

import Api
import Api.Post as Post
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { token : String
    , postContentId : Int
    , status : Post.Status
    }


type Response
    = Unauthorized
    | Success


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/post/translations/status"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "token", E.string req.token )
        , ( "post_content_id", E.int req.postContentId )
        , ( "status", Post.encodeStatus req.status )
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
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding Post.Translations.Status.Response"
