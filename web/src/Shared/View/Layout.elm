module Shared.View.Layout exposing (viewMenu)

import Css exposing (..)
import Css.Transitions as Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Shared



--  TODO
-- - em vs rem
-- - Following
-- - Preferences (tags + tag or user blocking)
-- - Reports
-- - Profile editing
-- - Post and comment editing / deleting
-- - Menu
-- - Bookmarks (posts.bookmarkedBy ["id1", "id2", ...])
-- - Settings and acount stuff
-- - Translations and separete comment sections
-- - Full text search
-- - Left and Right menus
-- - UI tweaks


viewMenu : Shared.Model -> msg -> Html msg
viewMenu shared onClick =
    let
        w =
            if shared.isMenuOpen then
                pct 90

            else
                pct 0
    in
    div
        []
        [ button
            [ Ev.onClick onClick
            , css
                [ position fixed
                , top (rem 1)
                , right (rem 1)
                , zIndex (int 1)
                , outline none
                , borderStyle none
                , backgroundColor shared.theme.mainColor
                , borderRadius <| rem 0.5
                , width <| rem 2
                , height <| rem 2
                , cursor pointer
                ]
            ]
            []
        , div
            [ css
                [ width w
                , maxWidth <| ch (80 * 0.7)
                , height <| pct 100
                , position fixed
                , top zero
                , right zero
                , backgroundColor shared.theme.backgroundColor
                , borderWidth4 zero zero zero (rem 0.18)
                , borderColor shared.theme.mainColor
                , borderStyle solid
                , displayFlex
                , flexDirection column
                , alignItems center
                , padding2 (rem 2) zero
                , if shared.isMenuOpen then
                    visibility visible

                  else
                    visibility hidden
                , opacity <|
                    if shared.isMenuOpen then
                        int 1

                    else
                        int 0
                , Transitions.transition
                    [ Transitions.width3 666 0 Transitions.easeInOut
                    , Transitions.opacity3 666 0 Transitions.easeInOut
                    , Transitions.visibility3 666 0 Transitions.easeInOut
                    ]
                ]
            ]
            [ a
                [ Attr.href "/"
                , css
                    [ fontSize shared.theme.largeFontSize
                    , color shared.theme.mainFontColor
                    , textDecoration none
                    ]
                ]
                [ text "Home" ]
            ]
        ]
