module Api.Post.Translation exposing (Translation, decoder)

import Json.Decode as D


type alias Translation =
    { postContentId : Int
    , languageId : Int
    , language : String
    }


decoder : D.Decoder Translation
decoder =
    D.map3 Translation
        (D.field "post_content_id" D.int)
        (D.field "language_id" D.int)
        (D.field "language" D.string)
