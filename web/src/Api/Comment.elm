module Api.Comment exposing (Comment, Reply, decoder, contentMaxLen)

import Json.Decode as D
import Api.User as User


type alias Reply =
    { commentId : Int
    , replyTo : User.Meta
    }


type alias Comment =
    { id : Int
    , postContentId : Int
    , replyTo : Maybe Reply
    , content : String
    , postedBy : User.Meta
    , postedAt : Int
    }


decoder : D.Decoder Comment
decoder =
    D.map6 Comment
        (D.field "id" D.int)
        (D.field "post_content_id" D.int)
        (D.field "reply_to" <| D.maybe replyDecoder)
        (D.field "content" D.string)
        (D.field "posted_by" User.metaDecoder)
        (D.field "posted_at" D.int)


replyDecoder : D.Decoder Reply
replyDecoder =
    D.map2 Reply
        (D.field "comment_id" D.int)
        (D.field "reply_to" User.metaDecoder)


contentMaxLen : Int
contentMaxLen =
    4096
