module Api.User.Bookmarks.Preferences exposing (Preferences(..), encode)

import Json.Encode as E


type Preferences
    = Unauthorized
        { languageIds : List Int
        }
    | Authorized
        { token : String
        }


encode : Preferences -> E.Value
encode preferences =
    case preferences of
        Unauthorized { languageIds } ->
            E.object
                [ ( "tag", E.string "Unauthorized" )
                , ( "language_ids", E.list E.int languageIds )
                ]

        Authorized { token } ->
            E.object
                [ ( "tag", E.string "Authorized" )
                , ( "token", E.string token )
                ]
