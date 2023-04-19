module Pages.Translations exposing (Model, Msg, page)

import Ago
import Api.Post as Post
import Api.Post.Translations.Status as PostTranslationsStatus
import Api.SignIn exposing (User(..))
import Api.User as User
import Api.User.Translations as UserTranslations exposing (Translation)
import Array exposing (Array)
import Css exposing (..)
import Css.Transitions as Transitions
import Effect exposing (Effect)
import Gen.Params.Translations exposing (Params)
import Html.Events as Events
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Http
import Json.Decode as D
import Json.Encode as E
import Language exposing (Language(..))
import Page
import Ports
import Reauth exposing (reauth)
import Request
import Shared
import Shared.View.PostedBy exposing (smallTextSpan, viewPostedBy, viewPostedByProfilePicture)
import Shared.View.Sign exposing (errorMessageSpan, inputStyle, messageSpan, successMessageSpan)
import Shared.View.TileButtons exposing (viewTileButtons)
import Status exposing (Status(..))
import Time
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.advanced
        { init = init shared
        , update = update shared
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type PostStatus
    = L Post.Status
    | S Post.Status
    | E Error


type alias Translation =
    { postId : Int
    , postContentId : Int
    , languageId : Int
    , language : String
    , title : String
    , status : PostStatus
    , postedBy : User.Meta
    , translatedBy : User.Meta
    , postedAt : Int
    , translatedAt : Int
    }


type Error
    = EndOfContent
    | ServerError


type Select
    = Mine (Array Translation)
    | Others (Array Translation)


type alias Model =
    { status : Status () Error
    , select : Select
    , search : String
    , limit : Int
    , offset : Int
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    let
        model =
            { status = Loading
            , select = Mine Array.empty
            , search = ""
            , limit = 20
            , offset = 0
            }
    in
    ( model, fetchTranslations shared model )



-- UPDATE


type Msg
    = Select Select
    | SearchChanged String
    | EndOfPageReached
    | PostStatusChanged Int Post.Status
    | Retry
    | GotTranslationsResponse (Result Http.Error UserTranslations.Response)
    | GotStatusResponse Int Post.Status (Result Http.Error PostTranslationsStatus.Response)


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        Select select ->
            let
                newModel =
                    { model | status = Loading, select = resetSelect select, offset = 0 }
            in
            ( newModel, fetchTranslations shared newModel )

        SearchChanged search ->
            let
                newModel =
                    { model | status = Loading, select = resetSelect model.select, offset = 0, search = search }
            in
            ( newModel, fetchTranslations shared newModel )

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
                ( { model | status = Loading }, fetchTranslations shared model )

            else
                ( model, Effect.none )

        PostStatusChanged i status ->
            ( updateModelTranslationStatus model i <| L status, sendStatusRequest shared model i status )

        Retry ->
            let
                isLoading t =
                    case t.status of
                        L _ ->
                            True

                        _ ->
                            False

                translations =
                    getTranslations model
            in
            if model.status == Loading then
                ( model, fetchTranslations shared model )

            else if not <| Array.isEmpty <| Array.filter isLoading <| getTranslations model then
                let
                    eff =
                        Effect.batch <|
                            Array.toList <|
                                Array.indexedMap (sendStatusRequestIfLoading shared model) translations
                in
                ( model, eff )

            else
                ( model, Effect.none )

        GotTranslationsResponse httpResponse ->
            case httpResponse of
                Ok UserTranslations.Unauthorized ->
                    ( model, reauth )

                Ok (UserTranslations.Success data) ->
                    let
                        transformedData =
                            Array.map fromApiTranslation <| Array.fromList data
                    in
                    case model.select of
                        Mine translations ->
                            if List.isEmpty data || List.length data < model.limit then
                                ( { model | status = Error EndOfContent, select = Mine <| Array.append translations transformedData, offset = model.offset + model.limit }, Effect.none )

                            else
                                ( { model | status = Success (), select = Mine <| Array.append translations transformedData, offset = model.offset + model.limit }, Effect.none )

                        Others translations ->
                            if List.isEmpty data || List.length data < model.limit then
                                ( { model | status = Error EndOfContent, select = Others <| Array.append translations transformedData, offset = model.offset + model.limit }, Effect.none )

                            else
                                ( { model | status = Success (), select = Others <| Array.append translations transformedData, offset = model.offset + model.limit }, Effect.none )

                Err _ ->
                    ( { model | status = Error ServerError }, Effect.none )

        GotStatusResponse i status httpResponse ->
            case httpResponse of
                Ok PostTranslationsStatus.Unauthorized ->
                    ( model, reauth )

                Ok PostTranslationsStatus.Success ->
                    ( updateModelTranslationStatus model i <| S status, Effect.none )

                Err _ ->
                    ( updateModelTranslationStatus model i <| E ServerError, Effect.none )



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
                        , property "gap" "2rem"
                        ]
                    ]
                    [ viewTileButtons shared translateSelect selectEq [ Mine Array.empty, Others Array.empty ] Select model.select
                    , input
                        [ Ev.onInput SearchChanged
                        , Attr.value model.search
                        , Attr.placeholder <| searchPlaceholder shared.language
                        , css <| inputStyle shared False
                        ]
                        []
                    , case model.select of
                        Mine translations ->
                            viewTranslations shared True translations

                        Others translations ->
                            viewTranslations shared False translations
                    , case model.status of
                        Idle ->
                            text ""

                        Loading ->
                            messageSpan shared <| loadingText shared.language

                        Success _ ->
                            text ""

                        Error error ->
                            messageSpan shared <| translateError shared.language error
                    ]
                ]
            ]
    }


viewTranslations : Shared.Model -> Bool -> Array Translation -> Html Msg
viewTranslations shared isMine translations =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , property "gap" "1.5rem"
            , width <| pct 100
            ]
        ]
        (Array.toList <| Array.indexedMap (viewTranslation shared isMine) translations)


fetchTranslations : Shared.Model -> Model -> Effect Msg
fetchTranslations shared model =
    case shared.user of
        Unauthorized ->
            Effect.none

        Authorized authorizedUser ->
            let
                req =
                    { token = authorizedUser.token
                    , isMine =
                        case model.select of
                            Mine _ ->
                                True

                            Others _ ->
                                False
                    , query = model.search
                    , limit = model.limit
                    , offset = model.offset
                    }
            in
            Effect.fromCmd <| UserTranslations.request req GotTranslationsResponse


selectEq : Select -> Select -> Bool
selectEq a b =
    case ( a, b ) of
        ( Mine _, Mine _ ) ->
            True

        ( Others _, Others _ ) ->
            True

        _ ->
            False


translateSelect : Language -> Select -> String
translateSelect language select =
    case select of
        Mine _ ->
            case language of
                English ->
                    "Mine"

                Ukrainian ->
                    "Мої"

        Others _ ->
            case language of
                English ->
                    "Others"

                Ukrainian ->
                    "Інших"


resetSelect : Select -> Select
resetSelect select =
    case select of
        Mine _ ->
            Mine Array.empty

        Others _ ->
            Others Array.empty


viewTranslation : Shared.Model -> Bool -> Int -> Translation -> Html Msg
viewTranslation shared isMine i translation =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , outline none
            , width <| calc (pct 100) minus (rem 2)
            , padding <| rem 1
            , borderRadius <| rem 1
            , border3 (rem 0.17) solid shared.theme.mainColor
            , backgroundColor transparent
            , textDecoration none
            ]
        ]
        [ a
            [ Attr.href <| "/post/" ++ String.fromInt translation.postContentId
            , css
                [ fontSize shared.theme.largeFontSize
                , textDecoration none
                , color shared.theme.mainFontColor
                , fontWeight bold
                , marginBottom <| rem 1
                , Transitions.transition
                    [ Transitions.color3 420 0 Transitions.easeIn
                    ]
                , hover
                    [ color shared.theme.accentFontColor
                    ]
                ]
            ]
            [ text translation.title ]
        , div
            [ css
                [ displayFlex
                , justifyContent spaceBetween
                , alignItems start
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
                [ viewPostedByProfilePicture translation.postedBy
                , let
                    nowMillis =
                        Time.posixToMillis shared.now

                    millisSincePostedAt =
                        nowMillis - translation.postedAt

                    secondsSincePostedAt =
                        millisSincePostedAt // 1000

                    postedAt =
                        Ago.format shared.language secondsSincePostedAt
                  in
                  viewPostedBy shared False translation.postedBy (smallTextSpan shared postedAt)
                ]
            , div
                [ css
                    [ displayFlex
                    , flexDirection column
                    , alignItems center
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
                    [ viewPostedByProfilePicture translation.translatedBy
                    , let
                        nowMillis =
                            Time.posixToMillis shared.now

                        millisSincePostedAt =
                            nowMillis - translation.postedAt

                        secondsSincePostedAt =
                            millisSincePostedAt // 1000

                        postedAt =
                            Ago.format shared.language secondsSincePostedAt
                      in
                      viewPostedBy shared False translation.translatedBy (smallTextSpan shared postedAt)
                    ]
                , case translation.status of
                    L _ ->
                        messageSpan shared <| loadingText shared.language

                    S s ->
                        viewPostStatus shared isMine i s

                    E error ->
                        errorMessageSpan shared <| translateError shared.language error
                ]
            ]
        ]


translatePostStatus : Language -> Post.Status -> String
translatePostStatus language status =
    case status of
        Post.Pending ->
            case language of
                English ->
                    "Pending"

                Ukrainian ->
                    "В обробці"

        Post.Approved ->
            case language of
                English ->
                    "Approved"

                Ukrainian ->
                    "Прийнято"

        Post.Denied ->
            case language of
                English ->
                    "Denied"

                Ukrainian ->
                    "Відхилено"


viewPostStatus : Shared.Model -> Bool -> Int -> Post.Status -> Html Msg
viewPostStatus shared isMine i status =
    let
        s =
            translatePostStatus shared.language status
    in
    if isMine then
        div
            [ css
                [ displayFlex
                , justifyContent center
                , fontWeight bold
                , backgroundColor shared.theme.accentColor
                , borderRadius <| rem 0.5
                , padding <| rem 0.5
                ]
            ]
            [ case status of
                Post.Pending ->
                    messageSpan shared s

                Post.Approved ->
                    successMessageSpan shared s

                Post.Denied ->
                    errorMessageSpan shared s
            ]

    else
        viewActionButtons shared i status


viewActionButtons : Shared.Model -> Int -> Post.Status -> Html Msg
viewActionButtons shared i status =
    case status of
        Post.Pending ->
            div
                [ css
                    [ displayFlex
                    , property "gap" "0.5rem"
                    , flexWrap wrap
                    ]
                ]
                [ viewApproveButton shared i
                , viewDenyButton shared i
                ]

        Post.Approved ->
            viewDenyButton shared i

        Post.Denied ->
            viewApproveButton shared i


viewApproveButton : Shared.Model -> Int -> Html Msg
viewApproveButton shared i =
    button
        [ Ev.onClick <| PostStatusChanged i Post.Approved
        , css
            [ outline none
            , cursor pointer
            , fontWeight bold
            , fontSize shared.theme.mediumFontSize
            , backgroundColor transparent
            , border3 (rem 0.17) solid shared.theme.mainColor
            , color shared.theme.successFontColor
            , padding <| rem 0.5
            , borderRadius <| rem 0.5
            , flexShrink zero
            , Transitions.transition
                [ Transitions.backgroundColor3 420 0 Transitions.easeIn
                , Transitions.color3 420 0 Transitions.easeIn
                ]
            , hover
                [ backgroundColor shared.theme.mainColor
                , color shared.theme.accentFontColor
                ]
            ]
        ]
        [ text <| approveText shared.language ]


viewDenyButton : Shared.Model -> Int -> Html Msg
viewDenyButton shared i =
    button
        [ Ev.onClick <| PostStatusChanged i Post.Denied
        , css
            [ outline none
            , cursor pointer
            , fontWeight bold
            , fontSize shared.theme.mediumFontSize
            , backgroundColor transparent
            , color shared.theme.errorFontColor
            , border3 (rem 0.17) solid shared.theme.mainColor
            , padding <| rem 0.5
            , borderRadius <| rem 0.5
            , flexShrink zero
            , Transitions.transition
                [ Transitions.backgroundColor3 420 0 Transitions.easeIn
                , Transitions.color3 420 0 Transitions.easeIn
                ]
            , hover
                [ backgroundColor shared.theme.mainColor
                , color shared.theme.accentFontColor
                ]
            ]
        ]
        [ text <| denyText shared.language ]


approveText : Language -> String
approveText language =
    case language of
        English ->
            "Approve"

        Ukrainian ->
            "Прийняти"


denyText : Language -> String
denyText language =
    case language of
        English ->
            "Deny"

        Ukrainian ->
            "Відхилити"


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


loadingText : Language -> String
loadingText language =
    case language of
        English ->
            "Loading..."

        Ukrainian ->
            "Завантажуємо..."


fromApiTranslation : UserTranslations.Translation -> Translation
fromApiTranslation apiTranslation =
    { postId = apiTranslation.postId
    , postContentId = apiTranslation.postContentId
    , languageId = apiTranslation.languageId
    , language = apiTranslation.language
    , title = apiTranslation.title
    , status = S apiTranslation.status
    , postedBy = apiTranslation.postedBy
    , translatedBy = apiTranslation.translatedBy
    , postedAt = apiTranslation.postedAt
    , translatedAt = apiTranslation.translatedAt
    }


updateTranslationStatus : Int -> PostStatus -> Array Translation -> Array Translation
updateTranslationStatus i status translations =
    case Array.get i translations of
        Just translation ->
            let
                newTranslation =
                    { translation | status = status }
            in
            case status of
                S Post.Approved ->
                    Array.set i newTranslation <|
                        Array.map
                            (\t ->
                                if t.postId == translation.postId then
                                    { t | status = S Post.Denied }

                                else
                                    t
                            )
                            translations

                _ ->
                    Array.set i newTranslation translations

        Nothing ->
            translations


updateModelTranslationStatus : Model -> Int -> PostStatus -> Model
updateModelTranslationStatus model i status =
    case model.select of
        Mine translations ->
            { model | select = Mine <| updateTranslationStatus i status translations }

        Others translations ->
            { model | select = Others <| updateTranslationStatus i status translations }


getTranslations : Model -> Array Translation
getTranslations model =
    case model.select of
        Mine translations ->
            translations

        Others translations ->
            translations


sendStatusRequest : Shared.Model -> Model -> Int -> Post.Status -> Effect Msg
sendStatusRequest shared model i status =
    case shared.user of
        Unauthorized ->
            Effect.none

        Authorized authorizedUser ->
            case Array.get i <| getTranslations model of
                Just translation ->
                    let
                        req =
                            { token = authorizedUser.token
                            , postContentId = translation.postContentId
                            , status = status
                            }
                    in
                    Effect.fromCmd <| PostTranslationsStatus.request req <| GotStatusResponse i status

                Nothing ->
                    Effect.none


sendStatusRequestIfLoading : Shared.Model -> Model -> Int -> Translation -> Effect Msg
sendStatusRequestIfLoading shared model i translation =
    case translation.status of
        L status ->
            sendStatusRequest shared model i status

        _ ->
            Effect.none


searchPlaceholder : Language -> String
searchPlaceholder language =
    case language of
        English ->
            "Search"

        Ukrainian ->
            "Пошук"
