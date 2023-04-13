module Api.User.Fetch exposing (Request, Response(..), request)

import Api exposing (encodeMaybe)
import Api.User as User exposing (User)
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { token : Maybe String
    , userId : Int
    }


type Response
    = Unauthorized
    | Success (Maybe User)


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/user/fetch"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "token", encodeMaybe E.string req.token )
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

        "Success" ->
            D.map Success
                (D.field "user" <| D.maybe User.decoder)

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding User.Fetch.Response"
