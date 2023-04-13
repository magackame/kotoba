module Api.SignIn exposing (Request, User(..), getRetoken, getToken, request, responseDecoder)

import Api
import Api.User as User
import Http
import Json.Decode as D
import Json.Encode as E


type alias Request =
    { email : String
    , password : String
    }


type User
    = Unauthorized
    | Authorized
        { token : String
        , retoken : String
        , userMeta : User.Meta
        }


type alias Response =
    User


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/sign-in"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse responseDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "email", E.string req.email )
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
        "Unauthorized" ->
            D.succeed Unauthorized

        "Authorized" ->
            D.map3 (\token retoken userMeta -> Authorized { token = token, retoken = retoken, userMeta = userMeta })
                (D.field "token" D.string)
                (D.field "retoken" D.string)
                (D.field "user_meta" User.metaDecoder)

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding SignIn.Response"


getToken : User -> Maybe String
getToken user =
    case user of
        Unauthorized ->
            Nothing

        Authorized authorizedUser ->
            Just authorizedUser.token


getRetoken : User -> Maybe String
getRetoken user =
    case user of
        Unauthorized ->
            Nothing

        Authorized authorizedUser ->
            Just authorizedUser.retoken
