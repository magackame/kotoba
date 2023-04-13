module Theme exposing (Theme, default)

import Css exposing (Color, Pct, Rem, pct, rem, rgb, rgba)


type alias Theme =
    { backgroundColor : Color
    , mainColor : Color
    , accentColor : Color
    , mainFontColor : Color
    , accentFontColor : Color
    , successFontColor : Color
    , errorFontColor : Color
    , largeFontSize : Rem
    , mediumFontSize : Rem
    , smallFontSize : Rem
    , contentFontSize : Rem
    , lineHeight : Pct
    }


mediumFontSize : Float
mediumFontSize =
    1


default : Theme
default =
    { backgroundColor = rgb 38 38 38
    , mainColor = rgb 255 192 203
    , accentColor = rgba 255 192 203 0.3
    , mainFontColor = rgb 255 192 203
    , accentFontColor = rgb 255 255 255
    , successFontColor = rgba 132 194 97 0.5
    , errorFontColor = rgba 207 81 72 0.5
    , largeFontSize = rem 2
    , mediumFontSize = rem 1
    , smallFontSize = rem 0.75
    , contentFontSize = rem 1.5
    , lineHeight = pct 150
    }
