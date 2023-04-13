module Pages.Home_ exposing (Model, Msg, page)

import Ago
import Api
import Api.Post as Post
import Api.Post.All as PostAll
import Api.Post.All.Preferences as PostAllPreferences
import Api.Post.Feed as PostFeed
import Api.Post.Feed.Preferences as PostFeedPreferences
import Api.SignIn exposing (User(..))
import Api.User as User
import Api.User.Search as UserSearch
import Css exposing (..)
import Css.Transitions as Transitions
import Effect exposing (Effect)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Http
import Language exposing (Language(..))
import Page
import Ports
import Reauth exposing (reauth)
import Request exposing (Request)
import Shared
import Shared.View.Layout exposing (viewMenu)
import Shared.View.Post exposing (viewPosts)
import Shared.View.PostedBy exposing (smallTextSpan, viewPostedBy, viewPostedByProfilePicture)
import Shared.View.Sign exposing (inputStyle)
import Shared.View.Tags exposing (tagStyle, viewTags)
import Shared.View.TileButtons exposing (viewTileButtons)
import Status exposing (Status(..))
import Theme
import Time
import View exposing (View)


type Error
    = EndOfContent
    | ServerError


type Select
    = All (List Post.Meta)
    | Feed (List Post.Meta)
    | People (List UserSearch.User)


type alias Model =
    { select : Select
    , status : Status () Error
    , search : String
    , limit : Int
    , offset : Int
    }


type Msg
    = Dummy
    | Select Select
    | SearchChanged String
    | MenuClicked
    | EndOfPageReached
    | Retry
    | GotAllResponse (Result Http.Error PostAll.Response)
    | GotFeedResponse (Result Http.Error PostFeed.Response)
    | GotPeopleResponse (Result Http.Error (List UserSearch.User))


page : Shared.Model -> Request -> Page.With Model Msg
page shared _ =
    Page.advanced
        { init = init shared
        , update = update shared
        , view = view shared
        , subscriptions = subscriptions
        }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    let
        model =
            { select = All []
            , status = Loading
            , search = ""
            , limit = 20
            , offset = 0
            }

        eff =
            fetchAll shared model
    in
    ( model, eff )


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        Dummy ->
            ( model, Effect.none )

        Select select ->
            let
                newModel =
                    { model | select = resetSelect select, status = Loading, offset = 0 }

                eff =
                    case select of
                        All _ ->
                            fetchAll shared newModel

                        Feed _ ->
                            fetchFeed shared newModel

                        People _ ->
                            fetchPeople newModel
            in
            ( newModel, eff )

        SearchChanged search ->
            let
                newModel =
                    { model | search = search, select = resetSelect model.select, status = Loading, offset = 0 }

                eff =
                    case model.select of
                        All _ ->
                            fetchAll shared newModel

                        Feed _ ->
                            fetchFeed shared newModel

                        People _ ->
                            fetchPeople newModel
            in
            ( newModel, eff )

        MenuClicked ->
            ( model, Effect.fromShared Shared.MenuClicked )

        EndOfPageReached ->
            let
                shouldFetch =
                    case model.status of
                        Idle ->
                            True

                        Success _ ->
                            True

                        _ ->
                            False
            in
            if shouldFetch then
                let
                    eff =
                        case model.select of
                            All _ ->
                                fetchAll shared model

                            Feed _ ->
                                fetchFeed shared model

                            People _ ->
                                fetchPeople model
                in
                ( { model | status = Loading }, eff )

            else
                ( model, Effect.none )

        Retry ->
            let
                eff =
                    case model.select of
                        All _ ->
                            fetchAll shared model

                        Feed _ ->
                            fetchFeed shared model

                        People _ ->
                            -- Shoudn't be possible. No auth in UserSearch.request
                            fetchPeople model
            in
            ( model, eff )

        GotAllResponse httpResponse ->
            case httpResponse of
                Ok response ->
                    case response of
                        PostAll.Unauthorized ->
                            ( model, reauth )

                        PostAll.Success data ->
                            case model.select of
                                All posts ->
                                    if List.isEmpty data || List.length data < model.limit then
                                        ( { model | select = All <| posts ++ data, status = Error EndOfContent, offset = model.offset + model.limit }, Effect.none )

                                    else
                                        ( { model | select = All <| posts ++ data, status = Success (), offset = model.offset + model.limit }, Effect.none )

                                _ ->
                                    ( model, Effect.none )

                Err _ ->
                    ( { model | status = Error ServerError }, Effect.none )

        GotFeedResponse httpResponse ->
            case httpResponse of
                Ok response ->
                    case response of
                        PostFeed.Unauthorized ->
                            ( model, reauth )

                        PostFeed.Success data ->
                            case model.select of
                                Feed posts ->
                                    if List.isEmpty data || List.length data < model.limit then
                                        ( { model | select = Feed <| posts ++ data, status = Error EndOfContent, offset = model.offset + model.limit }, Effect.none )

                                    else
                                        ( { model | select = Feed <| posts ++ data, status = Success (), offset = model.offset + model.limit }, Effect.none )

                                _ ->
                                    ( model, Effect.none )

                Err _ ->
                    ( { model | status = Error ServerError }, Effect.none )

        GotPeopleResponse httpResponse ->
            case httpResponse of
                Ok data ->
                    case model.select of
                        People people ->
                            if List.isEmpty data || List.length data < model.limit then
                                ( { model | select = People <| people ++ data, status = Error EndOfContent, offset = model.offset + model.limit }, Effect.none )

                            else
                                ( { model | select = People <| people ++ data, status = Success (), offset = model.offset + model.limit }, Effect.none )

                        _ ->
                            ( model, Effect.none )

                Err _ ->
                    ( { model | status = Error ServerError }, Effect.none )


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "kotoba"
    , body =
        List.map toUnstyled
            [ viewMenu shared MenuClicked
            , div
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
                        , property "gap" "2rem"
                        ]
                    ]
                    [ viewTileButtons shared translateSelect selectEq [ All [], Feed [], People [] ] Select model.select
                    , input
                        [ Ev.onInput SearchChanged
                        , Attr.value model.search
                        , Attr.placeholder <| searchPlaceholder shared.language
                        , css <| inputStyle shared False
                        ]
                        []
                    , case model.select of
                        All posts ->
                            viewPosts shared posts

                        Feed posts ->
                            viewPosts shared posts

                        People people ->
                            div
                                [ css
                                    [ displayFlex
                                    , flexDirection column
                                    , width <| pct 100
                                    , alignItems left
                                    , property "gap" "1.5rem"
                                    ]
                                ]
                                (List.map (viewUser shared) people)
                    , case model.status of
                        Idle ->
                            text "1"

                        Loading ->
                            text "LOADING"

                        Success _ ->
                            text "SUCCESS"

                        Error error ->
                            span
                                [ css
                                    [ fontSize shared.theme.largeFontSize
                                    , color shared.theme.mainFontColor
                                    ]
                                ]
                                [ text <| translateError shared.language error ]
                    ]
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.endOfPageReached (\_ -> EndOfPageReached)
        , Ports.retry (\_ -> Retry)
        ]


translateSelect : Language -> Select -> String
translateSelect language select =
    case select of
        All _ ->
            case language of
                English ->
                    "All"

                Ukrainian ->
                    "Все"

        Feed _ ->
            case language of
                English ->
                    "Feed"

                Ukrainian ->
                    "Рекомендації"

        People _ ->
            case language of
                English ->
                    "People"

                Ukrainian ->
                    "Люди"


searchPlaceholder : Language -> String
searchPlaceholder language =
    case language of
        English ->
            "Search"

        Ukrainian ->
            "Пошук"


fetchAll : Shared.Model -> Model -> Effect Msg
fetchAll shared model =
    let
        preferences =
            case shared.user of
                Unauthorized ->
                    PostAllPreferences.Unauthorized { languageIds = shared.languageIds }

                Authorized authorizedUser ->
                    PostAllPreferences.Authorized { token = authorizedUser.token }

        req =
            { preferences = preferences
            , query = model.search
            , limit = model.limit
            , offset = model.offset
            }
    in
    Effect.fromCmd <| PostAll.request req GotAllResponse


fetchFeed : Shared.Model -> Model -> Effect Msg
fetchFeed shared model =
    let
        preferences =
            case shared.user of
                Unauthorized ->
                    PostFeedPreferences.Unauthorized { languageIds = shared.languageIds, tagIds = shared.tagIds }

                Authorized authorizedUser ->
                    PostFeedPreferences.Authorized { token = authorizedUser.token }

        req =
            { preferences = preferences
            , query = model.search
            , limit = model.limit
            , offset = model.offset
            }
    in
    Effect.fromCmd <| PostFeed.request req GotFeedResponse


fetchPeople : Model -> Effect Msg
fetchPeople model =
    let
        req =
            { query = model.search
            , limit = model.limit
            , offset = model.offset
            }
    in
    Effect.fromCmd <| UserSearch.request req GotPeopleResponse


resetSelect : Select -> Select
resetSelect select =
    case select of
        All _ ->
            All []

        Feed _ ->
            Feed []

        People _ ->
            People []


selectEq : Select -> Select -> Bool
selectEq a b =
    case ( a, b ) of
        ( All _, All _ ) ->
            True

        ( Feed _, Feed _ ) ->
            True

        ( People _, People _ ) ->
            True

        _ ->
            False


viewUser : Shared.Model -> UserSearch.User -> Html Msg
viewUser shared user =
    a
        [ Attr.href <| "/user/" ++ String.fromInt user.id
        , css
            [ displayFlex
            , flexDirection column
            , property "gap" "1rem"
            , padding <| rem 1
            , borderRadius <| rem 1
            , textDecoration none
            , width <| calc (pct 100) minus (rem 2)
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
        [ div
            [ css
                [ displayFlex
                , property "column-gap" "1rem"
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
                        ]
                    ]
                    [ text user.handle ]
                , span
                    [ css
                        [ fontSize shared.theme.mediumFontSize
                        , color shared.theme.accentFontColor
                        ]
                    ]
                    [ text user.fullName ]
                ]
            ]
        ]


translateError : Language -> Error -> String
translateError language error =
    case error of
        EndOfContent ->
            case language of
                English ->
                    "That's all!"

                Ukrainian ->
                    "Це все!"

        ServerError ->
            case language of
                English ->
                    "Server error"

                Ukrainian ->
                    "Помилка на сервері"
