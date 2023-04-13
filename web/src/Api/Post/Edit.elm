module Api.Post.Edit exposing (Request, Response(..), request)

import Api
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { token : String
    , postContentId : Int
    , languageId : Int
    , title : String
    , description : String
    , tags : List String
    , content : String
    }


type Response
    = Unauthorized
    | Success


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/post/edit"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "token", E.string req.token )
        , ( "post_content_id", E.int req.postContentId )
        , ( "language_id", E.int req.languageId )
        , ( "title", E.string req.title )
        , ( "description", E.string req.description )
        , ( "tags", E.list E.string req.tags )
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
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding Post.Edit.Response"
