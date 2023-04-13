module Pages.User.Id_ exposing (Model, Msg, page)

import Api
import Api.Comment as Comment exposing (Comment)
import Api.Post as Post
import Api.SignIn exposing (User(..), getToken)
import Api.User as User
import Api.User.Bookmarks as UserBookmarks
import Api.User.Bookmarks.Preferences as UserBookmarksPreferences
import Api.User.Comments as UserComments
import Api.User.Fetch as UserFetch
import Api.User.Follows as UserFollows
import Api.User.Follows.Fetch as UserFollowsFetch
import Api.User.Posts as UserPosts
import Api.User.Posts.Preferences as UserPostsPreferences
import Css exposing (..)
import Css.Transitions as Transitions
import Effect exposing (Effect)
import Gen.Params.User.Id_ exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Http
import Language exposing (Language(..))
import Page
import Ports
import Reauth exposing (reauth)
import Request
import Shared
import Shared.View.Comment exposing (replyToStyle, viewComment, viewComments)
import Shared.View.Post exposing (viewPosts)
import Shared.View.PostedBy exposing (smallTextSpan, viewPostedBy, viewPostedByProfilePicture)
import Shared.View.Sign exposing (inputStyle)
import Shared.View.TileButtons exposing (viewTileButtons)
import Status exposing (Status(..))
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init req.params.id shared
        , update = update req.params.id shared
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type alias ApiUser =
    User.User


type Select
    = Posts (List Post.Meta)
    | Comments (List Comment)
    | Bookmarks (List Post.Meta)
    | Follows (List User.Meta)


type Error
    = UserNotFound
    | InvalidPermissions
    | EndOfContent
    | ServerError


type alias Model =
    { status : Status ApiUser Error
    , followStatus : Status () Error
    , isFollowed : Bool
    , isHoveringOverFollowButton : Bool
    , select : Select
    , selectStatus : Status () Error
    , search : String
    , limit : Int
    , offset : Int
    }


init : String -> Shared.Model -> ( Model, Effect Msg )
init id shared =
    let
        model =
            { status = Loading
            , followStatus = Idle
            , isFollowed = False
            , isHoveringOverFollowButton = False
            , select = Posts []
            , selectStatus = Loading
            , search = ""
            , limit = 20
            , offset = 0
            }

        effs =
            Effect.batch
                [ fetchUser id shared
                , fetchPosts id shared model
                ]
    in
    ( model, effs )



-- UPDATE


type Msg
    = GotUserResponse (Result Http.Error UserFetch.Response)
    | Retry
    | IsHoveringOverFollowButtonChanged Bool
    | FollowClicked
    | SearchChanged String
    | GotFollowsResponse (Result Http.Error UserFollows.Response)
    | Select Select
    | EndOfPageReached
    | GotPostsResponse (Result Http.Error UserPosts.Response)
    | GotCommentsResponse (Result Http.Error (List Comment))
    | GotBookmarksResponse (Result Http.Error UserBookmarks.Response)
    | GotFollowsFetchResponse (Result Http.Error (List User.Meta))


update : String -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update id shared msg model =
    case msg of
        GotUserResponse httpResponse ->
            case httpResponse of
                Ok UserFetch.Unauthorized ->
                    ( model, reauth )

                Ok (UserFetch.Success (Just u)) ->
                    ( { model | status = Success u, isFollowed = u.isFollowed }, Effect.none )

                Ok (UserFetch.Success Nothing) ->
                    ( { model | status = Error UserNotFound }, Effect.none )

                Err _ ->
                    ( { model | status = Error ServerError }, Effect.none )

        Retry ->
            let
                eff =
                    case ( model.status, model.followStatus, model.selectStatus ) of
                        ( Success u, Loading, _ ) ->
                            sendFollowsRequest shared u.id

                        ( _, _, Loading ) ->
                            case model.select of
                                Posts _ ->
                                    fetchPosts id shared model

                                Bookmarks _ ->
                                    fetchBookmarks id shared model

                                -- Comments and Follows don't do auth
                                -- and hence don't need reauth
                                _ ->
                                    Effect.none

                        _ ->
                            fetchUser id shared
            in
            ( model, eff )

        IsHoveringOverFollowButtonChanged isHoveringOverFollowButton ->
            ( { model | isHoveringOverFollowButton = isHoveringOverFollowButton }, Effect.none )

        FollowClicked ->
            case model.status of
                Success user ->
                    ( model, sendFollowsRequest shared user.id )

                _ ->
                    ( model, Effect.none )

        SearchChanged search ->
            let
                newModel =
                    { model | selectStatus = Loading, offset = 0, search = search }
            in
            case model.select of
                Posts _ ->
                    ( { newModel | select = Posts [] }, fetchPosts id shared newModel )

                Comments _ ->
                    ( { newModel | select = Comments [] }, fetchComments id newModel )

                Bookmarks _ ->
                    ( { newModel | select = Bookmarks [] }, fetchBookmarks id shared newModel )

                Follows _ ->
                    ( { newModel | select = Follows [] }, fetchFollows id newModel )

        GotFollowsResponse httpResponse ->
            case httpResponse of
                Ok UserFollows.Unauthorized ->
                    ( model, reauth )

                Ok UserFollows.InvalidPermissions ->
                    ( { model | followStatus = Error InvalidPermissions }, Effect.none )

                Ok UserFollows.Success ->
                    ( { model | followStatus = Success (), isFollowed = not model.isFollowed }, Effect.none )

                Err _ ->
                    ( { model | followStatus = Error ServerError }, Effect.none )

        Select select ->
            let
                newModel =
                    { model | selectStatus = Loading, offset = 0 }
            in
            case select of
                Posts _ ->
                    ( { newModel | select = Posts [] }, fetchPosts id shared newModel )

                Comments _ ->
                    ( { newModel | select = Comments [] }, fetchComments id newModel )

                Bookmarks _ ->
                    ( { newModel | select = Bookmarks [] }, fetchBookmarks id shared newModel )

                Follows _ ->
                    ( { newModel | select = Follows [] }, fetchFollows id newModel )

        EndOfPageReached ->
            let
                shouldFetch =
                    case model.selectStatus of
                        Idle ->
                            True

                        Success _ ->
                            True

                        _ ->
                            False
            in
            if shouldFetch then
                case model.select of
                    Posts _ ->
                        ( { model | selectStatus = Loading }, fetchPosts id shared model )

                    Comments _ ->
                        ( { model | selectStatus = Loading }, fetchComments id model )

                    Bookmarks _ ->
                        ( { model | selectStatus = Loading }, fetchBookmarks id shared model )

                    Follows _ ->
                        ( { model | selectStatus = Loading }, fetchFollows id model )

            else
                ( model, Effect.none )

        GotPostsResponse httpResponse ->
            case httpResponse of
                Ok UserPosts.Unauthorized ->
                    ( model, reauth )

                Ok (UserPosts.Success data) ->
                    case model.select of
                        Posts posts ->
                            if List.length data == 0 || List.length data < model.limit then
                                ( { model | select = Posts <| posts ++ data, selectStatus = Error EndOfContent, offset = model.offset + model.limit }, Effect.none )

                            else
                                ( { model | select = Posts <| posts ++ data, selectStatus = Success (), offset = model.offset + model.limit }, Effect.none )

                        _ ->
                            ( model, Effect.none )

                Err _ ->
                    ( { model | selectStatus = Error ServerError }, Effect.none )

        GotCommentsResponse httpResponse ->
            case httpResponse of
                Ok data ->
                    case model.select of
                        Comments comments ->
                            if List.isEmpty data || List.length data < model.limit then
                                ( { model | selectStatus = Error EndOfContent, select = Comments <| comments ++ data, offset = model.offset + model.limit }, Effect.none )

                            else
                                ( { model | selectStatus = Success (), select = Comments <| comments ++ data, offset = model.offset + model.limit }, Effect.none )

                        _ ->
                            ( model, Effect.none )

                Err _ ->
                    ( { model | selectStatus = Error ServerError }, Effect.none )

        GotBookmarksResponse httpResponse ->
            case httpResponse of
                Ok UserBookmarks.Unauthorized ->
                    ( model, reauth )

                Ok (UserBookmarks.Success data) ->
                    case model.select of
                        Bookmarks posts ->
                            if List.length data == 0 || List.length data < model.limit then
                                ( { model | select = Bookmarks <| posts ++ data, selectStatus = Error EndOfContent, offset = model.offset + model.limit }, Effect.none )

                            else
                                ( { model | select = Bookmarks <| posts ++ data, selectStatus = Success (), offset = model.offset + model.limit }, Effect.none )

                        _ ->
                            ( model, Effect.none )

                Err _ ->
                    ( { model | selectStatus = Error ServerError }, Effect.none )

        GotFollowsFetchResponse httpResponse ->
            case httpResponse of
                Ok data ->
                    case model.select of
                        Follows follows ->
                            if List.isEmpty data || List.length data < model.limit then
                                ( { model | selectStatus = Error EndOfContent, select = Follows <| follows ++ data, offset = model.offset + model.limit }, Effect.none )

                            else
                                ( { model | selectStatus = Success (), select = Follows <| follows ++ data, offset = model.offset + model.limit }, Effect.none )

                        _ ->
                            ( model, Effect.none )

                Err _ ->
                    ( { model | selectStatus = Error ServerError }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.endOfPageReached (\_ -> EndOfPageReached)
        , Ports.retry (\_ -> Retry)
        ]



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "kotoba"
    , body =
        List.map toUnstyled
            [ div
                [ css
                    [ displayFlex
                    , justifyContent center
                    ]
                ]
                [ div
                    [ css
                        [ displayFlex
                        , flexDirection column
                        , alignItems center
                        , padding2 (rem 2) (rem 1)
                        , width <| calc (pct 100) minus (rem 2)
                        , maxWidth <| ch 80
                        ]
                    ]
                    [ case model.status of
                        Idle ->
                            text "1"

                        Loading ->
                            text "2"

                        Success user ->
                            div
                                [ css
                                    [ displayFlex
                                    , flexDirection column
                                    , width <| pct 100
                                    , property "gap" "2rem"
                                    ]
                                ]
                                [ div
                                    [ css
                                        [ displayFlex
                                        , property "gap" "1rem"
                                        , flexWrap wrap
                                        ]
                                    ]
                                    [ img
                                        [ Attr.alt user.handle
                                        , Attr.src <| Api.pfpUrl user.profilePictureFileName
                                        , css
                                            [ width <| rem 8
                                            , height <| rem 8
                                            , flexShrink zero
                                            , borderRadius <| pct 50
                                            ]
                                        ]
                                        []
                                    , div
                                        [ css
                                            [ displayFlex
                                            , flexDirection column
                                            , paddingTop <| rem 1
                                            , property "gap" "1rem"
                                            ]
                                        ]
                                        [ span
                                            [ css
                                                [ fontSize shared.theme.largeFontSize
                                                , color shared.theme.mainFontColor
                                                , fontWeight bold
                                                , textDecoration none
                                                ]
                                            ]
                                            [ text user.handle ]
                                        , span
                                            [ css
                                                [ fontSize shared.theme.mediumFontSize
                                                , color shared.theme.accentFontColor
                                                , textDecoration none
                                                , Transitions.transition
                                                    [ Transitions.color3 420 0 Transitions.easeIn
                                                    ]
                                                , hover
                                                    [ color shared.theme.accentFontColor
                                                    ]
                                                ]
                                            ]
                                            [ text user.fullName ]
                                        ]
                                    ]
                                , viewFollowButton shared model.isFollowed model.isHoveringOverFollowButton user
                                , span
                                    [ css
                                        [ fontSize shared.theme.contentFontSize
                                        , color shared.theme.accentFontColor
                                        ]
                                    ]
                                    [ text user.description ]
                                , viewTileButtons shared translateSelect selectEq (addOptionalSelects shared user [ Posts [], Comments [] ]) Select model.select
                                , input
                                    [ Ev.onInput SearchChanged
                                    , Attr.value model.search
                                    , Attr.placeholder <| searchPlaceholder shared.language
                                    , css <| inputStyle shared False
                                    ]
                                    []
                                , case model.select of
                                    Posts posts ->
                                        viewPosts shared posts

                                    Comments comments ->
                                        viewComments (viewCommentWithReply shared) comments

                                    Bookmarks bookmarks ->
                                        viewPosts shared bookmarks

                                    Follows following ->
                                        div
                                            [ css
                                                [ displayFlex
                                                , property "gap" "0.5rem"
                                                , flexWrap wrap
                                                ]
                                            ]
                                            (List.map (viewFollowing shared) following)

                                -- viewFollowing shared model.following
                                ]

                        Error _ ->
                            text "4"
                    ]
                ]
            ]
    }


viewFollowing : Shared.Model -> User.Meta -> Html Msg
viewFollowing shared user =
    a
        [ Attr.href <| "/user/" ++ String.fromInt user.id
        , css
            [ displayFlex
            , alignItems center
            , property "gap" "1rem"
            , textDecoration none
            , padding <| rem 0.5
            , borderRadius <| rem 0.5
            , hover
                [ backgroundColor shared.theme.accentColor
                ]
            , Transitions.transition
                [ Transitions.backgroundColor3 420 0 Transitions.easeIn
                ]
            ]
        ]
        [ viewPostedByProfilePicture user
        , viewPostedBy shared True user (smallTextSpan shared "")
        ]


translateSelect : Language -> Select -> String
translateSelect language select =
    case select of
        Posts _ ->
            case language of
                English ->
                    "Posts"

                Ukrainian ->
                    "Пости"

        Comments _ ->
            case language of
                English ->
                    "Comments"

                Ukrainian ->
                    "Коментарі"

        Bookmarks _ ->
            case language of
                English ->
                    "Bookmarks"

                Ukrainian ->
                    "Закладки"

        Follows _ ->
            case language of
                English ->
                    "Following"

                Ukrainian ->
                    "Підписки"


addOptionalSelects : Shared.Model -> ApiUser -> List Select -> List Select
addOptionalSelects shared user =
    addFollowingSelect shared user << addBookmarksSelect shared user


addBookmarksSelect : Shared.Model -> ApiUser -> List Select -> List Select
addBookmarksSelect shared user selects =
    let
        shouldShowBookmarks =
            case shared.user of
                Unauthorized ->
                    not <| user.isBookmarksPrivate

                Authorized authorizedUser ->
                    authorizedUser.userMeta.id == user.id || not user.isBookmarksPrivate
    in
    if shouldShowBookmarks then
        selects ++ [ Bookmarks [] ]

    else
        selects


addFollowingSelect : Shared.Model -> ApiUser -> List Select -> List Select
addFollowingSelect shared user selects =
    let
        shouldShowFollowing =
            case shared.user of
                Unauthorized ->
                    not <| user.isFollowingPrivate

                Authorized authorizedUser ->
                    authorizedUser.userMeta.id == user.id || not user.isFollowingPrivate
    in
    if shouldShowFollowing then
        selects ++ [ Follows [] ]

    else
        selects


viewCommentWithReply : Shared.Model -> Comment -> Html Msg
viewCommentWithReply shared comment =
    viewComment shared (viewReplyTo shared comment) (text "") comment


followButtonText : Language -> String
followButtonText language =
    case language of
        English ->
            "Follow"

        Ukrainian ->
            "Підписатися"


followingButtonText : Language -> String
followingButtonText language =
    case language of
        English ->
            "Following"

        Ukrainian ->
            "Підписано"


unfollowButtonText : Language -> String
unfollowButtonText language =
    case language of
        English ->
            "Unfollow"

        Ukrainian ->
            "Відписатися"


viewReplyTo : Shared.Model -> Comment -> Html Msg
viewReplyTo shared comment =
    case comment.replyTo of
        Just replyTo ->
            a
                -- TODO: `href` to post
                [ css <| replyToStyle shared
                ]
                [ text <| "↳ " ++ replyTo.replyTo.handle ]

        Nothing ->
            text ""


viewFollowButton : Shared.Model -> Bool -> Bool -> User.User -> Html Msg
viewFollowButton shared isFollowed isHoveringOverFollowButton user =
    case shared.user of
        Unauthorized ->
            text ""

        Authorized authorizedUser ->
            if authorizedUser.userMeta.id == user.id then
                text ""

            else if isFollowed then
                viewUnfollowButton shared isHoveringOverFollowButton

            else
                viewDoFollowButton shared


viewDoFollowButton : Shared.Model -> Html Msg
viewDoFollowButton shared =
    button
        [ Ev.onClick FollowClicked
        , css
            [ outline none
            , maxWidth <| rem 12
            , border3 (rem 0.18) solid shared.theme.mainColor
            , borderRadius <| rem 0.5
            , fontSize shared.theme.mediumFontSize
            , padding <| rem 0.5
            , backgroundColor shared.theme.backgroundColor
            , cursor pointer
            , color shared.theme.mainFontColor
            , fontWeight bold
            , hover
                [ backgroundColor shared.theme.mainColor
                , color shared.theme.accentFontColor
                ]
            , Transitions.transition
                [ Transitions.borderColor3 420 0 Transitions.easeIn
                , Transitions.color3 420 0 Transitions.easeIn
                , Transitions.backgroundColor3 420 0 Transitions.easeIn
                ]
            ]
        ]
        [ text <| followButtonText shared.language ]


viewUnfollowButton : Shared.Model -> Bool -> Html Msg
viewUnfollowButton shared isHoveringOverFollowButton =
    button
        [ Ev.onMouseEnter <| IsHoveringOverFollowButtonChanged True
        , Ev.onMouseLeave <| IsHoveringOverFollowButtonChanged False
        , Ev.onClick FollowClicked
        , css
            [ outline none
            , maxWidth <| rem 12
            , backgroundColor shared.theme.mainColor
            , borderRadius <| rem 0.5
            , fontSize shared.theme.mediumFontSize
            , fontWeight bold
            , padding <| rem 0.5
            , cursor pointer
            , color shared.theme.accentFontColor
            , border3 (rem 0.18) solid transparent
            , hover
                [ backgroundColor transparent
                , borderColor shared.theme.mainColor
                , color shared.theme.mainFontColor
                ]
            , Transitions.transition
                [ Transitions.borderColor3 420 0 Transitions.easeIn
                , Transitions.color3 420 0 Transitions.easeIn
                , Transitions.backgroundColor3 420 0 Transitions.easeIn
                ]
            ]
        ]
        [ text <|
            if isHoveringOverFollowButton then
                unfollowButtonText shared.language

            else
                followingButtonText shared.language
        ]


sendFollowsRequest : Shared.Model -> Int -> Effect Msg
sendFollowsRequest shared userId =
    case getToken shared.user of
        Just token ->
            Effect.fromCmd <| UserFollows.request { token = token, userId = userId } GotFollowsResponse

        Nothing ->
            Effect.fromShared <| Shared.Redirect "/sign-in"


fetchUser : String -> Shared.Model -> Effect Msg
fetchUser id shared =
    let
        token =
            getToken shared.user

        userId =
            Maybe.withDefault 0 <| String.toInt id
    in
    Effect.fromCmd <| UserFetch.request { token = token, userId = userId } GotUserResponse


fetchPosts : String -> Shared.Model -> Model -> Effect Msg
fetchPosts id shared model =
    let
        preferences =
            case getToken shared.user of
                Just token ->
                    UserPostsPreferences.Authorized { token = token }

                Nothing ->
                    UserPostsPreferences.Unauthorized { languageIds = shared.languageIds }

        userId =
            Maybe.withDefault 0 <| String.toInt id

        req =
            { preferences = preferences
            , userId = userId
            , query = model.search
            , limit = model.limit
            , offset = model.offset
            }
    in
    Effect.fromCmd <| UserPosts.request req GotPostsResponse


selectEq : Select -> Select -> Bool
selectEq a b =
    case ( a, b ) of
        ( Posts _, Posts _ ) ->
            True

        ( Comments _, Comments _ ) ->
            True

        ( Bookmarks _, Bookmarks _ ) ->
            True

        ( Follows _, Follows _ ) ->
            True

        _ ->
            False


searchPlaceholder : Language -> String
searchPlaceholder language =
    case language of
        English ->
            "Search"

        Ukrainian ->
            "Пошук"


fetchComments : String -> Model -> Effect Msg
fetchComments id model =
    case String.toInt id of
        Just userId ->
            let
                req =
                    { userId = userId
                    , query = model.search
                    , limit = model.limit
                    , offset = model.offset
                    }
            in
            Effect.fromCmd <| UserComments.request req GotCommentsResponse

        Nothing ->
            Effect.none


fetchFollows : String -> Model -> Effect Msg
fetchFollows id model =
    case String.toInt id of
        Just userId ->
            let
                req =
                    { userId = userId
                    , query = model.search
                    , limit = model.limit
                    , offset = model.offset
                    }
            in
            Effect.fromCmd <| UserFollowsFetch.request req GotFollowsFetchResponse

        Nothing ->
            Effect.none


fetchBookmarks : String -> Shared.Model -> Model -> Effect Msg
fetchBookmarks id shared model =
    let
        preferences =
            case getToken shared.user of
                Just token ->
                    UserBookmarksPreferences.Authorized { token = token }

                Nothing ->
                    UserBookmarksPreferences.Unauthorized { languageIds = shared.languageIds }

        userId =
            Maybe.withDefault 0 <| String.toInt id

        req =
            { preferences = preferences
            , userId = userId
            , query = model.search
            , limit = model.limit
            , offset = model.offset
            }
    in
    Effect.fromCmd <| UserBookmarks.request req GotBookmarksResponse
