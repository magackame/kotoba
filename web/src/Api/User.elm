module Api.User exposing (Meta, Role(..), User, roleDecoder, metaDecoder, decoder)

import Json.Decode as D
import Json.Decode.Pipeline as DP
import Json.Encode as E


type Role
    = Admin
    | Mod
    | Member
    | Banned
    | Unverified


type alias Meta =
    { id : Int
    , handle : String
    , profilePictureFileName : Maybe String
    }


type alias User =
    { id : Int
    , handle : String
    , profilePictureFileName : Maybe String
    , role : Role
    , fullName : String
    , description : String
    , joinedAt : Int
    , isBookmarksPrivate : Bool
    , isFollowingPrivate : Bool
    , isFollowed : Bool
    }


decoder : D.Decoder User
decoder =
    D.succeed User
        |> DP.required "id" D.int
        |> DP.required "handle" D.string
        |> DP.required "profile_picture_file_name" (D.nullable D.string)
        |> DP.required "role" roleDecoder
        |> DP.required "full_name" D.string
        |> DP.required "description" D.string
        |> DP.required "joined_at" D.int
        |> DP.required "is_bookmarks_private" D.bool
        |> DP.required "is_following_private" D.bool
        |> DP.required "is_followed" D.bool


metaDecoder : D.Decoder Meta
metaDecoder =
    D.map3 Meta
        (D.field "id" D.int)
        (D.field "handle" D.string)
        (D.field "profile_picture_file_name" <| D.maybe D.string)


roleDecoder : D.Decoder Role
roleDecoder =
    D.andThen
        roleInnerDecoder
        (D.field "tag" D.string)


roleInnerDecoder : String -> D.Decoder Role
roleInnerDecoder tag =
    case tag of
        "Admin" ->
            D.succeed Admin

        "Mod" ->
            D.succeed Mod

        "Member" ->
            D.succeed Member

        "Banned" ->
            D.succeed Banned

        "Unverified" ->
            D.succeed Unverified

        _ ->
            D.fail <| "Encountered unknown tag `" ++ tag ++ "` while decoding User.Role"

