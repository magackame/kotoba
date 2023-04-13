module Shared.View.Post exposing (viewPost, viewPosts)

import Ago
import Api.Post as Post
import Css exposing (..)
import Css.Transitions as Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Shared
import Shared.View.PostedBy exposing (smallTextSpan, viewPostedBy, viewPostedByProfilePicture)
import Shared.View.Tags exposing (tagStyle, viewTags)
import Time


viewPosts : Shared.Model -> List Post.Meta -> Html msg
viewPosts shared posts =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , alignItems center
            , width <| pct 100
            , property "gap" "1.5rem"
            ]
        ]
        (List.map (viewPost shared) posts)


viewPost : Shared.Model -> Post.Meta -> Html msg
viewPost shared postMeta =
    a
        [ Attr.href <| "/post/" ++ String.fromInt postMeta.postContentId
        , css
            [ displayFlex
            , flexDirection column
            , outline none
            , cursor pointer

            -- , width <| pct 100
            , width <| calc (pct 100) minus (rem 2)
            , padding <| rem 1
            , borderRadius <| rem 1
            , border3 (rem 0.17) solid shared.theme.mainColor
            , backgroundColor transparent
            , textDecoration none
            , Transitions.transition
                [ Transitions.backgroundColor3 420 0 Transitions.easeIn
                , Transitions.borderColor3 420 0 Transitions.easeIn
                ]
            , hover
                [ backgroundColor shared.theme.accentColor
                , borderColor transparent
                ]
            ]
        ]
        [ span
            [ css
                [ fontSize shared.theme.largeFontSize
                , color shared.theme.mainFontColor
                , fontWeight bold
                , marginBottom <| rem 1
                ]
            ]
            [ text postMeta.title ]
        , span
            [ css
                [ fontSize shared.theme.mediumFontSize
                , color shared.theme.accentFontColor
                , marginBottom <| rem 1
                ]
            ]
            [ text postMeta.description ]
        , div
            [ css
                [ displayFlex
                , alignItems center
                , flexWrap wrap
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
                [ viewPostedByProfilePicture postMeta.postedBy
                , let
                    nowMillis =
                        Time.posixToMillis shared.now

                    millisSincePostedAt =
                        nowMillis - postMeta.postedAt

                    secondsSincePostedAt =
                        millisSincePostedAt // 1000

                    postedAt =
                        Ago.format shared.language secondsSincePostedAt
                  in
                  viewPostedBy shared False postMeta.postedBy (smallTextSpan shared postedAt)
                ]
            , viewTags False (\tag -> span [ css <| tagStyle shared ] [ text tag ]) postMeta.tags
            ]
        ]
