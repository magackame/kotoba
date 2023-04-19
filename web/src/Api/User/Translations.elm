module Api.User.Translations exposing (Request, Response(..), Translation, request)

import Api
import Api.Post as Post
import Api.User as User
import Http
import Json.Decode as D
import Json.Decode.Pipeline as DP
import Json.Encode as E


type alias Translation =
    { postId : Int
    , postContentId : Int
    , languageId : Int
    , language : String
    , title : String
    , status : Post.Status
    , postedBy : User.Meta
    , translatedBy : User.Meta
    , postedAt : Int
    , translatedAt : Int
    }


type alias Request =
    { token : String
    , isMine : Bool
    , query : String
    , limit : Int
    , offset : Int
    }


type Response
    = Unauthorized
    | Success (List Translation)


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/user/translations"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "token", E.string req.token )
        , ( "is_mine", E.bool req.isMine )
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
                (D.field "page" <| D.list translationDecoder)

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding Post.All.Response"


translationDecoder : D.Decoder Translation
translationDecoder =
    D.succeed Translation
        |> DP.required "post_id" D.int
        |> DP.required "post_content_id" D.int
        |> DP.required "language_id" D.int
        |> DP.required "language" D.string
        |> DP.required "title" D.string
        |> DP.required "status" Post.statusDecoder
        |> DP.required "posted_by" User.metaDecoder
        |> DP.required "translated_by" User.metaDecoder
        |> DP.required "posted_at" D.int
        |> DP.required "translated_at" D.int
