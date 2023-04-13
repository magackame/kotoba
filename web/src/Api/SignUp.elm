module Api.SignUp exposing (Request, Response(..), request)

import Api
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { handle : String
    , email : String
    , password : String
    }


type Response
    = HandleAlreadyTaken
    | EmailAlreadyTaken
    | InvalidEmail
    | Success


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/sign-up"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "handle", E.string req.handle )
        , ( "email", E.string req.email )
        , ( "password", E.string req.password )
        ]


responseDecoder : D.Decoder Response
responseDecoder =
    D.andThen
        responseInnerDecoder
        (D.field "tag" D.string)


responseInnerDecoder : String -> D.Decoder Response
responseInnerDecoder tag =
    case tag of
        "EmailAlreadyTaken" ->
            D.succeed EmailAlreadyTaken

        "HandleAlreadyTaken" ->
            D.succeed HandleAlreadyTaken

        "InvalidEmail" ->
            D.succeed InvalidEmail

        "Success" ->
            D.succeed Success

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding SignUp.Response"
