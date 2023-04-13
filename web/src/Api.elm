module Api exposing (prefix, pfpUrl, encodeMaybe)


import Json.Encode as E


prefix : String
prefix = "http://localhost:3000/api"


pfpUrl : Maybe String -> String
pfpUrl profilePictureFileName =
    case profilePictureFileName of
        Just fileName ->
            prefix ++ "/images/" ++ fileName
        Nothing ->
            "https://www.wiresmithtech.com/wp-content/uploads/rust-logo-512x512-1.png"

            
encodeMaybe : (a -> E.Value) -> Maybe a -> E.Value
encodeMaybe e m =
    case m of
        Just a ->
            e a

        Nothing ->
            E.null
