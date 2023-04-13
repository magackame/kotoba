module Api.Language exposing (Language, decoder)

import Json.Decode as D


type alias Language =
    { id : Int
    , name : String
    }


decoder : D.Decoder Language
decoder =
    D.map2 Language
        (D.field "id" D.int)
        (D.field "name" D.string)
