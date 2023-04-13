module Api.User.Follows exposing (Request, Response(..), request)

import Api
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { token : String
    , userId : Int
    }


type Response
    = Unauthorized
    | InvalidPermissions
    | Success


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/user/follows"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "token", E.string req.token )
        , ( "user_id", E.int req.userId )
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

        "InvalidPermissions" ->
            D.succeed InvalidPermissions

        "Success" ->
            D.succeed Success

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding User.Follows.Response"
