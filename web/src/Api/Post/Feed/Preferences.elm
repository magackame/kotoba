module Api.Post.Feed.Preferences exposing (Preferences(..), encode)

import Json.Encode as E


type Preferences
    = Unauthorized
        { languageIds : List Int
        , tagIds : List Int
        }
    | Authorized
        { token : String
        }


encode : Preferences -> E.Value
encode preferences =
    case preferences of
        Unauthorized { languageIds, tagIds } ->
            E.object
                [ ( "tag", E.string "Unauthorized" )
                , ( "language_ids", E.list E.int languageIds )
                , ( "tag_ids", E.list E.int tagIds )
                ]

        Authorized { token } ->
            E.object
                [ ( "tag", E.string "Authorized" )
                , ( "token", E.string token )
                ]
