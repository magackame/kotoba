module Shared.View.Comment exposing (replyToStyle, viewComment, viewComments)

import Api.Comment as Comment exposing (Comment)
import Css exposing (..)
import Css.Transitions as Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Shared
import Shared.View.PostedBy exposing (smallTextSpan, viewPostedBy, viewPostedByProfilePicture)


viewComments : (Comment -> Html msg) -> List Comment -> Html msg
viewComments view comments =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , property "gap" "1.5rem"
            ]
        ]
        (List.map view comments)


viewComment : Shared.Model -> Html msg -> Html msg -> Comment -> Html msg
viewComment shared replyTo reply comment =
    div
        [ Attr.id <| String.fromInt comment.id
        , css
            [ displayFlex
            , flexDirection column
            , padding2 (rem 1) (rem 1)
            , width <| calc (pct 100) minus (rem 2)
            , borderRadius <| rem 1
            , border3 (rem 0.17) solid shared.theme.mainColor
            , property "gap" "1rem"
            ]
        ]
        [ div
            [ css
                [ displayFlex
                , alignItems center
                , property "gap" "1rem"
                ]
            ]
            [ viewPostedByProfilePicture comment.postedBy
            , viewPostedBy shared True comment.postedBy replyTo
            ]
        , span
            [ css
                [ fontSize shared.theme.contentFontSize
                , lineHeight shared.theme.lineHeight
                , color shared.theme.mainFontColor
                ]
            ]
            [ text comment.content ]
        , reply
        ]


replyToStyle : Shared.Model -> List Style
replyToStyle shared =
    [ outline none
    , borderStyle none
    , textDecoration none
    , backgroundColor transparent
    , color shared.theme.accentFontColor
    , padding <| rem 0.3
    , borderRadius <| rem 0.3
    , fontSize shared.theme.smallFontSize
    , fontWeight bold
    , cursor pointer
    , Transitions.transition
        [ Transitions.backgroundColor3 420 0 Transitions.easeIn
        ]
    , hover
        [ backgroundColor shared.theme.accentColor
        ]
    ]
