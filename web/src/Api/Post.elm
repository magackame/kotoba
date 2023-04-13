module Api.Post exposing (Meta, Post, contentMaxLen, decoder, descriptionMaxLen, metaDecoder, tagMaxLen, tagsMaxAmount, tagsMinAmount, titleMaxLen)

import Api.Translation as Translation exposing (Translation)
import Api.User as User
import Json.Decode as D
import Json.Decode.Pipeline as DP


type alias Meta =
    { id : Int
    , postContentId : Int
    , title : String
    , description : String
    , tags : List String
    , postedBy : User.Meta
    , postedAt : Int
    }


type alias Post =
    { id : Int
    , postContentId : Int
    , languageId : Int
    , language : String
    , translations : List Translation
    , title : String
    , description : String
    , tags : List String
    , content : String
    , postedBy : User.Meta
    , translatedBy : User.Meta
    , postedAt : Int
    , translatedAt : Int
    , isBookmarked : Bool
    }


metaDecoder : D.Decoder Meta
metaDecoder =
    D.map7 Meta
        (D.field "id" D.int)
        (D.field "post_content_id" D.int)
        (D.field "title" D.string)
        (D.field "description" D.string)
        (D.field "tags" <| D.list D.string)
        (D.field "posted_by" User.metaDecoder)
        (D.field "posted_at" D.int)


decoder : D.Decoder Post
decoder =
    D.succeed Post
        |> DP.required "id" D.int
        |> DP.required "post_content_id" D.int
        |> DP.required "language_id" D.int
        |> DP.required "language" D.string
        |> DP.required "translations" (D.list Translation.decoder)
        |> DP.required "title" D.string
        |> DP.required "description" D.string
        |> DP.required "tags" (D.list D.string)
        |> DP.required "content" D.string
        |> DP.required "posted_by" User.metaDecoder
        |> DP.required "translated_by" User.metaDecoder
        |> DP.required "posted_at" D.int
        |> DP.required "translated_at" D.int
        |> DP.required "is_bookmarked" D.bool


titleMaxLen : Int
titleMaxLen =
    128


descriptionMaxLen : Int
descriptionMaxLen =
    256


tagMaxLen : Int
tagMaxLen =
    16


tagsMinAmount : Int
tagsMinAmount =
    2


tagsMaxAmount : Int
tagsMaxAmount =
    7


contentMaxLen : Int
contentMaxLen =
    8192
