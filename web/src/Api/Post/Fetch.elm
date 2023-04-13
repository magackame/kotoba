module Api.Post.Fetch exposing (Request, Response(..), request)

import Api exposing (encodeMaybe)
import Api.Post as Post exposing (Post)
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { token : Maybe String
    , postContentId : Int
    }


type Response
    = Unauthorized
    | Success (Maybe Post)


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/post/fetch"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "token", encodeMaybe E.string req.token )
        , ( "post_content_id", E.int req.postContentId )
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
            D.map Success
                (D.field "post" <| D.maybe Post.decoder)

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding Post.Fetch.Response"
