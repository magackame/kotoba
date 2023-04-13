module Api.Post.Feed exposing (Request, Response(..), request)

import Api
import Api.Post as Post
import Api.Post.Feed.Preferences as Preferences exposing (Preferences)
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { preferences : Preferences
    , query : String
    , limit : Int
    , offset : Int
    }


type Response
    = Unauthorized
    | Success (List Post.Meta)


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/post/feed"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "preferences", Preferences.encode req.preferences )
        , ( "query", E.string req.query )
        , ( "limit", E.int req.limit )
        , ( "offset", E.int req.offset )
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
                (D.field "page" <| D.list Post.metaDecoder)

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding Post.All.Response"
