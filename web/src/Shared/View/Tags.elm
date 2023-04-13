module Shared.View.Tags exposing (tagStyle, viewTags)

import Css exposing (..)
import Css.Transitions as Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Shared


viewTags : Bool -> (String -> Html msg) -> List String -> Html msg
viewTags shouldWrap viewTag tags =
    div
        [ css
            ([ displayFlex
             , alignItems center
             , overflow hidden
             , property "gap" "0.5rem"
             ]
                ++ (if shouldWrap then
                        [ flexWrap wrap ]

                    else
                        []
                   )
            )
        ]
        (List.map viewTag tags)


tagStyle : Shared.Model -> List Style
tagStyle shared =
    [ color shared.theme.accentFontColor
    , backgroundColor shared.theme.accentColor
    , fontSize shared.theme.mediumFontSize
    , outline none
    , borderStyle none
    , borderRadius <| rem 0.5
    , padding <| rem 0.5
    , cursor pointer
    , flexShrink zero
    , Transitions.transition
        [ Transitions.backgroundColor3 420 0 Transitions.easeIn
        , Transitions.color3 420 0 Transitions.easeIn
        ]
    , hover
        [ backgroundColor transparent
        , color shared.theme.mainFontColor
        ]
    ]
