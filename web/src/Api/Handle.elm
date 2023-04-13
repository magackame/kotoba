module Api.Handle exposing (isValid, maxLen, regex)

import Regex exposing (Regex)


maxLen : Int
maxLen =
    32


regex : String
regex =
    "^[A-z0-9_\\-]+$"


isValid : String -> Bool
isValid handle =
    String.isEmpty <| Regex.replace r (\_ -> "") handle


r : Regex
r =
    Maybe.withDefault Regex.never <| Regex.fromString regex
