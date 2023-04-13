module Shared.View.TileButtons exposing (viewTileButtons)

import Css exposing (..)
import Css.Transitions as Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Language exposing (Language(..))
import Shared


viewTileButtons : Shared.Model -> (Language -> a -> String) -> (a -> a -> Bool) -> List a -> (a -> msg) -> a -> Html msg
viewTileButtons shared translate eq values toMsg currentValue =
    div
        [ css
            [ displayFlex
            , property "row-gap" "0.5rem"
            , property "column-gap" "1.5rem"
            , flexWrap wrap
            ]
        ]
        (List.map (viewTileButton shared translate eq toMsg currentValue) values)


viewTileButton : Shared.Model -> (Language -> a -> String) -> (a -> a -> Bool) -> (a -> msg) -> a -> a -> Html msg
viewTileButton shared translate eq onClick currentValue value =
    let
        borderColor =
            if eq value currentValue then
                shared.theme.mainColor

            else
                rgba 0 0 0 0
    in
    button
        [ Ev.onClick <| onClick value
        , css
            [ outline none
            , borderWidth4 zero zero (rem 0.2) zero
            , borderBottomColor borderColor
            , fontSize shared.theme.mediumFontSize
            , padding <| rem 0.5
            , color shared.theme.mainFontColor
            , fontWeight bold
            , backgroundColor transparent
            , cursor pointer
            , Transitions.transition
                [ Transitions.borderColor3 420 0 Transitions.easeIn
                ]
            ]
        ]
        [ text <| translate shared.language value ]
