module Shared.View.PostForm exposing (..)

import Api.Language as ApiLanguage
import Api.Post as Post
import Api.SignIn exposing (User(..))
import Css exposing (..)
import Css.Transitions as Transitions
import Effect exposing (Effect)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Http
import Language exposing (Language(..))
import Set exposing (Set)
import Shared
import Shared.View.PostForm.LanguageFetchError as LanguageFetchError exposing (LanguageFetchError)
import Shared.View.Sign exposing (..)
import Shared.View.Tags exposing (tagStyle, viewTags)
import Status exposing (Status(..))
import View exposing (View)



-- INIT


type alias ApiLanguage =
    ApiLanguage.Language


type alias LanguageFetcher =
    String -> (Result Http.Error (List ApiLanguage) -> Msg) -> Cmd Msg


type Error
    = LanguageIsRequired
    | TitleIsRequired
    | DescriptionIsRequired
    | NotEnoughTags
    | ContentIsRequired
    | ServerError


type alias Model =
    { fetchLanguages : LanguageFetcher
    , selectedLanguage : Maybe ApiLanguage
    , language : String
    , languageStatus : Status () LanguageFetchError
    , languageSuggestions : List ApiLanguage
    , title : String
    , description : String
    , tag : String
    , tags : Set String
    , content : String
    , status : Status () Error
    }


init : LanguageFetcher -> ( Model, Effect Msg )
init fetchLanguages =
    let
        model =
            { fetchLanguages = fetchLanguages
            , selectedLanguage = Nothing
            , language = ""
            , languageStatus = Idle
            , languageSuggestions = []
            , title = ""
            , description = ""
            , tag = ""
            , tags = Set.empty
            , content = ""
            , status = Idle
            }
    in
    ( validate model, Effect.none )



-- UPDATE


type Msg
    = SelectedLanguageChanged ApiLanguage
    | SelectedLanguageClicked
    | LanguageChanged String
    | GotLanguageFetchResponse (Result Http.Error (List ApiLanguage))
    | TitleChanged String
    | DescriptionChanged String
    | TagChanged String
    | TagClicked String
    | ContentChanged String
    | SendClicked


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SelectedLanguageChanged selectedLanguage ->
            ( validate <| setSelectedLanguage selectedLanguage model, Effect.none )

        SelectedLanguageClicked ->
            ( validate { model | selectedLanguage = Nothing }, Effect.none )

        LanguageChanged language ->
            ( validate { model | language = language }, Effect.fromCmd <| model.fetchLanguages language GotLanguageFetchResponse )

        GotLanguageFetchResponse httpResponse ->
            case httpResponse of
                Ok response ->
                    let
                        languageStatus =
                            if List.isEmpty response then
                                Error LanguageFetchError.NothingFound

                            else
                                Success ()

                        newModel =
                            { model | languageStatus = languageStatus }
                    in
                    case find model.language response of
                        Just selectedLanguage ->
                            ( setSelectedLanguage selectedLanguage newModel, Effect.none )

                        Nothing ->
                            ( { newModel | languageSuggestions = response }, Effect.none )

                Err _ ->
                    ( { model | languageStatus = Error LanguageFetchError.ServerError }, Effect.none )

        TitleChanged title ->
            let
                newModel =
                    { model | title = title }
            in
            ( validate newModel, Effect.none )

        DescriptionChanged description ->
            let
                newModel =
                    { model | description = description }
            in
            ( validate newModel, Effect.none )

        TagChanged tag ->
            if String.length tag /= 1 && String.endsWith " " tag then
                ( validate { model | tags = Set.insert tag model.tags, tag = "" }, Effect.none )

            else
                ( { model | tag = String.replace " " "" tag }, Effect.none )

        TagClicked tag ->
            ( { model | tags = Set.remove tag model.tags }, Effect.none )

        ContentChanged content ->
            let
                newModel =
                    { model | content = content }
            in
            ( validate newModel, Effect.none )

        SendClicked ->
            -- Host should take over this and handle
            -- sending the request, retrying on reauth
            -- and updating the status
            ( model, Effect.none )



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
                    [ viewPostCreateForm shared model
                    ]
                ]
            ]
    }


viewPostCreateForm : Shared.Model -> Model -> Html Msg
viewPostCreateForm shared model =
    case shared.user of
        Unauthorized ->
            a
                [ Attr.href "/sign-in"
                , css
                    [ textDecoration none
                    , textAlign center
                    , fontSize <| shared.theme.largeFontSize
                    , color <| shared.theme.mainFontColor
                    , cursor pointer
                    , Transitions.transition
                        [ Transitions.color3 420 0 Transitions.easeIn
                        ]
                    , hover
                        [ color shared.theme.accentFontColor
                        ]
                    ]
                ]
                [ text <| youMustSignInText shared.language ]

        Authorized _ ->
            let
                isLanguageError =
                    case model.status of
                        Error LanguageIsRequired ->
                            True

                        _ ->
                            False

                isTitleError =
                    case model.status of
                        Error TitleIsRequired ->
                            True

                        _ ->
                            False

                isDescriptionError =
                    case model.status of
                        Error DescriptionIsRequired ->
                            True

                        _ ->
                            False
            in
            div
                [ css
                    [ displayFlex
                    , flexDirection column
                    , width <| pct 100
                    , property "gap" "1.5rem"
                    , alignItems center
                    ]
                ]
                [ case model.selectedLanguage of
                    Just language ->
                        button
                            [ Ev.onClick SelectedLanguageClicked
                            , css <| tagStyle shared
                            ]
                            [ text language.name ]

                    Nothing ->
                        div
                            [ css
                                [ displayFlex
                                , flexDirection column
                                , property "gap" "1rem"
                                , width <| pct 100
                                ]
                            ]
                            [ input
                                [ Attr.placeholder <| languageInputPlaceholder shared.language

                                -- , Attr.maxlength Post.titleMaxLen
                                , Attr.value model.language
                                , Ev.onInput LanguageChanged
                                , css <| inputStyle shared isLanguageError
                                ]
                                []
                            , div
                                [ css
                                    [ displayFlex
                                    , flexWrap wrap
                                    , property "gap" "0.5rem"
                                    ]
                                ]
                                (List.map (viewLanguage shared) model.languageSuggestions)
                            ]
                , input
                    [ Attr.placeholder <| titleInputPlaceholder shared.language
                    , Attr.maxlength Post.titleMaxLen
                    , Attr.value model.title
                    , Ev.onInput TitleChanged
                    , css <| inputStyle shared isTitleError
                    ]
                    []
                , input
                    [ Attr.placeholder <| descriptionInputPlaceholder shared.language
                    , Attr.maxlength Post.descriptionMaxLen
                    , Attr.value model.description
                    , Ev.onInput DescriptionChanged
                    , css <| inputStyle shared isDescriptionError
                    ]
                    []
                , if Set.size model.tags /= Post.tagsMaxAmount then
                    input
                        [ Attr.placeholder <| tagInputPlaceholder shared.language

                        -- + 1 because of space character needed to add tag
                        , Attr.maxlength <| Post.tagMaxLen + 1
                        , Attr.value model.tag
                        , Ev.onInput TagChanged
                        , css <| inputStyle shared False
                        ]
                        []

                  else
                    text ""
                , viewTags True (\tag -> button [ Ev.onClick <| TagClicked tag, css <| tagStyle shared ] [ text tag ]) <| Set.toList model.tags
                , let
                    isContentError =
                        case model.status of
                            Error ContentIsRequired ->
                                True

                            _ ->
                                False
                  in
                  textarea
                    [ Attr.rows 5
                    , Attr.placeholder <| contentInputPlaceholder shared.language
                    , Attr.value model.content
                    , Ev.onInput ContentChanged
                    , css
                        [ outline none
                        , padding2 (rem 1) (rem 1)
                        , borderRadius <| rem 1
                        , borderStyle none
                        , backgroundColor shared.theme.accentColor
                        , fontSize shared.theme.contentFontSize
                        , color shared.theme.accentFontColor
                        , resize none
                        , width <| calc (pct 100) minus (rem 2)
                        , backgroundColor <|
                            if isContentError then
                                shared.theme.errorFontColor

                            else
                                shared.theme.accentColor
                        , Transitions.transition
                            [ Transitions.backgroundColor3 420 0 Transitions.easeIn
                            ]
                        ]
                    ]
                    []
                , case model.status of
                    Idle ->
                        button
                            [ Ev.onClick SendClicked
                            , css <| buttonStyle shared
                            ]
                            [ text <| postCreateButtonText shared.language ]

                    Loading ->
                        messageSpan shared <| postCreateLoadingText shared.language

                    Success _ ->
                        successMessageSpan shared ""

                    Error error ->
                        errorMessageSpan shared <| translateError shared.language error
                ]


languageInputPlaceholder : Language -> String
languageInputPlaceholder language =
    case language of
        English ->
            "Language"

        Ukrainian ->
            "Мова"


titleInputPlaceholder : Language -> String
titleInputPlaceholder language =
    case language of
        English ->
            "Title"

        Ukrainian ->
            "Назва"


descriptionInputPlaceholder : Language -> String
descriptionInputPlaceholder language =
    case language of
        English ->
            "Description"

        Ukrainian ->
            "Опис"


tagInputPlaceholder : Language -> String
tagInputPlaceholder language =
    case language of
        English ->
            "Tag"

        Ukrainian ->
            "Тег"


contentInputPlaceholder : Language -> String
contentInputPlaceholder language =
    case language of
        English ->
            "Content"

        Ukrainian ->
            "Зміст"


postCreateButtonText : Language -> String
postCreateButtonText language =
    case language of
        English ->
            "Publish"

        Ukrainian ->
            "Опубліковати"


youMustSignInText : Language -> String
youMustSignInText language =
    case language of
        English ->
            "You must sign in to create posts"

        Ukrainian ->
            "Для того щоб створювати пости Вам необхідно увійти"


postCreateLoadingText : Language -> String
postCreateLoadingText language =
    case language of
        English ->
            "Loading..."

        Ukrainian ->
            "Зберігаємо..."


translateError : Language -> Error -> String
translateError language error =
    case error of
        LanguageIsRequired ->
            case language of
                English ->
                    "Enter the language"

                Ukrainian ->
                    "Ввеідть мову"

        TitleIsRequired ->
            case language of
                English ->
                    "Enter the title"

                Ukrainian ->
                    "Введіть назву"

        DescriptionIsRequired ->
            case language of
                English ->
                    "Enter the description"

                Ukrainian ->
                    "Введіть опис"

        NotEnoughTags ->
            case language of
                English ->
                    "You must add at least " ++ String.fromInt Post.tagsMinAmount ++ " tags"

                Ukrainian ->
                    -- TODO: format suffix based on minAmount
                    "Вам необхідно додати хоча б " ++ String.fromInt Post.tagsMinAmount ++ " теги"

        ContentIsRequired ->
            case language of
                English ->
                    "Enter the content"

                Ukrainian ->
                    "Введіть зміст"

        ServerError ->
            case language of
                English ->
                    "Server error"

                Ukrainian ->
                    "Помилка на сервері"


validate : Model -> Model
validate model =
    if model.selectedLanguage == Nothing && String.isEmpty model.language then
        { model | status = Error LanguageIsRequired }

    else if String.isEmpty model.title then
        { model | status = Error TitleIsRequired }

    else if String.isEmpty model.description then
        { model | status = Error DescriptionIsRequired }

    else if Set.size model.tags < Post.tagsMinAmount then
        { model | status = Error NotEnoughTags }

    else if String.isEmpty model.content then
        { model | status = Error ContentIsRequired }

    else
        { model | status = Idle }


viewLanguage : Shared.Model -> ApiLanguage -> Html Msg
viewLanguage shared language =
    button
        [ Ev.onClick <| SelectedLanguageChanged language
        , css <| tagStyle shared
        ]
        [ text language.name ]


find : String -> List ApiLanguage -> Maybe ApiLanguage
find name languages =
    case languages of
        language :: langs ->
            if name == language.name then
                Just language

            else
                find name langs

        [] ->
            Nothing


setSelectedLanguage : ApiLanguage -> Model -> Model
setSelectedLanguage selectedLanguage model =
    { model | selectedLanguage = Just selectedLanguage, language = "", languageSuggestions = [] }
