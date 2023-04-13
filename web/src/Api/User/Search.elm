module Api.User.Search exposing (Request, User, request)

import Api
import Http
import Json.Decode as D
import Json.Encode as E


type alias User =
    { id : Int
    , handle : String
    , profilePictureFileName : Maybe String
    , fullName : String
    , description : String
    }


type alias Request =
    { query : String
    , limit : Int
    , offset : Int
    }


type alias Response =
    List User


request : Request -> (Result Http.Error Response -> msg) -> Cmd msg
request req gotResponse =
    Http.post
        { url = Api.prefix ++ "/user/search"
        , body = Http.jsonBody <| encodeRequest req
        , expect = Http.expectJson gotResponse <| D.list userDecoder
        }


encodeRequest : Request -> E.Value
encodeRequest req =
    E.object
        [ ( "query", E.string req.query )
        , ( "limit", E.int req.limit )
        , ( "offset", E.int req.offset )
        ]


userDecoder : D.Decoder User
userDecoder =
    D.map5 User
        (D.field "id" D.int)
        (D.field "handle" D.string)
        (D.field "profile_picture_file_name" <| D.maybe D.string)
        (D.field "full_name" D.string)
        (D.field "description" D.string)
