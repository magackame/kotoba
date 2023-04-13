module Shared.View.PostedBy exposing (smallTextSpan, viewPostedBy, viewPostedByProfilePicture)

import Api
import Api.User as User
import Css exposing (..)
import Css.Transitions as Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Shared


viewPostedByProfilePicture : User.Meta -> Html msg
viewPostedByProfilePicture postedBy =
    img
        [ Attr.alt postedBy.handle
        , Attr.src <| Api.pfpUrl postedBy.profilePictureFileName
        , css
            [ width <| rem 3
            , height <| rem 3
            , flexShrink zero
            , borderRadius <| pct 50
            ]
        ]
        []


smallTextSpan : Shared.Model -> String -> Html msg
smallTextSpan shared s =
    span
        [ css
            [ fontSize shared.theme.smallFontSize
            , color shared.theme.accentFontColor
            ]
        ]
        [ text s ]


viewPostedBy : Shared.Model -> Bool -> User.Meta -> Html msg -> Html msg
viewPostedBy shared link postedBy postedAt =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , justifyContent center
            , property "gap" "0.5rem"
            ]
        ]
        [ (if link then
            a

           else
            span
          )
            [ Attr.href <| "/user/" ++ String.fromInt postedBy.id
            , css
                [ fontSize shared.theme.mediumFontSize
                , color shared.theme.mainFontColor
                , fontWeight bold
                , textDecoration none
                , Transitions.transition
                    [ Transitions.color3 420 0 Transitions.easeIn
                    ]
                , hover
                    [ color shared.theme.accentFontColor
                    ]
                ]
            ]
            [ text postedBy.handle ]
        , postedAt
        ]
