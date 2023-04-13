module Shared.View.Sign exposing (buttonStyle, errorMessageSpan, inputStyle, messageSpan, successMessageSpan, viewForm, viewPasswordVisibilityButton)

import Css exposing (..)
import Css.Transitions as Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Shared


messageSpan : Shared.Model -> String -> Html msg
messageSpan shared content =
    innerMessageSpan shared shared.theme.mainFontColor content


errorMessageSpan : Shared.Model -> String -> Html msg
errorMessageSpan shared content =
    innerMessageSpan shared shared.theme.errorFontColor content


successMessageSpan : Shared.Model -> String -> Html msg
successMessageSpan shared content =
    innerMessageSpan shared shared.theme.successFontColor content


innerMessageSpan : Shared.Model -> Color -> String -> Html msg
innerMessageSpan shared fontColor content =
    span
        [ css
            [ fontSize shared.theme.mediumFontSize
            , color fontColor
            , textAlign center
            ]
        ]
        [ text content ]


viewForm : Shared.Model -> List (Html msg) -> Html msg
viewForm shared children =
    div
        [ css
            [ displayFlex
            , justifyContent center
            , border3 (rem 0.17) solid shared.theme.mainColor
            , borderRadius <| rem 1
            , width <| calc (pct 100) minus (rem 2)
            , padding2 (rem 2) (rem 1)
            ]
        ]
        [ div
            [ css
                [ displayFlex
                , flexDirection column
                , alignItems center
                , property "gap" "1.5rem"
                , width <| pct 100
                , maxWidth <| ch (80 * 0.7)
                ]
            ]
            children
        ]


inputStyle : Shared.Model -> Bool -> List Style
inputStyle shared isError =
    [ width <| pct 96
    , textAlign center
    , padding2 (rem 0.5) (pct 2)
    , outline none
    , borderStyle none
    , borderRadius <| rem 0.5
    , fontSize shared.theme.mediumFontSize
    , color shared.theme.accentFontColor
    , backgroundColor <|
        if isError then
            shared.theme.errorFontColor

        else
            shared.theme.accentColor
    , Transitions.transition
        [ Transitions.backgroundColor3 420 0 Transitions.easeIn
        ]
    ]


buttonStyle : Shared.Model -> List Style
buttonStyle shared =
    [ outline none
    , borderStyle none
    , width <| pct 100
    , maxWidth <| ch (80 * 0.4)
    , borderRadius <| rem 0.5
    , padding <| rem 0.5
    , backgroundColor shared.theme.accentColor
    , color shared.theme.accentFontColor
    , fontSize shared.theme.mediumFontSize
    , cursor pointer
    , Transitions.transition
        [ Transitions.backgroundColor3 420 0 Transitions.easeIn
        , Transitions.color3 420 0 Transitions.easeIn
        ]
    , hover
        [ backgroundColor transparent
        , color shared.theme.mainFontColor
        ]
    ]


viewPasswordVisibilityButton : Shared.Model -> Bool -> msg -> Html msg
viewPasswordVisibilityButton shared passwordIsVisible switchPasswordVisibilityMsg =
    button
        [ Ev.onClick switchPasswordVisibilityMsg
        , css
            [ position absolute
            , bottom <| rem 0.5
            , right <| rem 0.5
            , outline none
            , borderStyle none
            , backgroundColor transparent
            , fontSize shared.theme.mediumFontSize
            , cursor pointer
            ]
        ]
        [ text <|
            if passwordIsVisible then
                "\u{1FAE3}"

            else
                "👀"
        ]
