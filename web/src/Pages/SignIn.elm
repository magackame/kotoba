module Pages.SignIn exposing (Model, Msg, page)

import Api.Email as Email
import Api.Password as Password
import Api.SignIn as SignIn exposing (User(..))
import Browser.Navigation as Nav exposing (Key)
import Css exposing (..)
import Css.Transitions as Transitions
import Effect exposing (Effect)
import Gen.Params.SignIn exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Http
import Language exposing (Language(..), emailInputPlaceholder, passwordInputPlaceholder)
import LocalStorage exposing (setLocalStorage)
import Page
import Request
import Shared
import Shared.View.Sign exposing (..)
import Status exposing (Status(..))
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.advanced
        { init = init
        , update = update shared
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type Error
    = EmailIsRequired
    | PasswordIsRequired
    | InvalidEmailOrPassword
    | ServerError


translateError : Language -> Error -> String
translateError language error =
    case error of
        EmailIsRequired ->
            case language of
                English ->
                    "Enter your email"

                Ukrainian ->
                    "Введіть електронну пошту"

        PasswordIsRequired ->
            case language of
                English ->
                    "Enter your password"

                Ukrainian ->
                    "Введіть пароль"

        InvalidEmailOrPassword ->
            case language of
                English ->
                    "Invalid email or password"

                Ukrainian ->
                    "Неправильна електронна пошта або пароль"

        ServerError ->
            case language of
                English ->
                    "Server error"

                Ukrainian ->
                    "Помилка на сервері"


type alias Model =
    { email : String
    , password : String
    , rememberMe : Bool
    , passwordIsVisible : Bool
    , status : Status () Error
    }


init : ( Model, Effect Msg )
init =
    let
        model =
            { email = ""
            , password = ""
            , rememberMe = False
            , passwordIsVisible = False
            , status = Idle
            }
    in
    ( validate model, Effect.none )



-- UPDATE


type Msg
    = EmailChanged String
    | PasswordChanged String
    | RememberMeChanged Bool
    | SwitchPasswordVisibility
    | SignInClicked
    | GotSignInResponse (Result Http.Error User)


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        EmailChanged email ->
            let
                newModel =
                    { model | email = email }
            in
            ( validate newModel, Effect.none )

        PasswordChanged password ->
            let
                newModel =
                    { model | password = password }
            in
            ( validate newModel, Effect.none )

        RememberMeChanged rememberMe ->
            ( { model | rememberMe = rememberMe }, Effect.none )

        SwitchPasswordVisibility ->
            ( { model | passwordIsVisible = not model.passwordIsVisible }, Effect.none )

        SignInClicked ->
            ( { model | status = Loading }, Effect.fromCmd <| SignIn.request { email = model.email, password = model.password } GotSignInResponse )

        GotSignInResponse httpResponse ->
            case httpResponse of
                Ok Unauthorized ->
                    ( { model | status = Error InvalidEmailOrPassword }, Effect.none )

                Ok (Authorized authorizedUser) ->
                    ( { model | status = Success () }, Effect.fromShared <| Shared.Auth model.rememberMe authorizedUser )

                Err _ ->
                    ( { model | status = Error ServerError }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



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
                        , maxWidth <| ch 80
                        , width <| calc (pct 100) minus (rem 2)
                        ]
                    ]
                    [ viewSignInForm shared model
                    ]
                ]
            ]
    }


rememberMeText : Language -> String
rememberMeText language =
    case language of
        English ->
            "Remember me"

        Ukrainian ->
            "Запам'ятайте мене"


validate : Model -> Model
validate model =
    if String.isEmpty model.email then
        { model | status = Error EmailIsRequired }

    else if String.isEmpty model.password then
        { model | status = Error PasswordIsRequired }

    else
        { model | status = Idle }


viewSignInForm : Shared.Model -> Model -> Html Msg
viewSignInForm shared model =
    let
        isEmailError =
            case model.status of
                Error EmailIsRequired ->
                    True

                _ ->
                    False

        isPasswordError =
            case model.status of
                Error PasswordIsRequired ->
                    True

                _ ->
                    False
    in
    viewForm
        shared
        [ input
            [ Attr.placeholder <| emailInputPlaceholder shared.language
            , Attr.maxlength Email.maxLen
            , Attr.type_ "email"
            , Attr.value model.email
            , Ev.onInput EmailChanged
            , css <| inputStyle shared isEmailError
            ]
            []
        , div
            [ css
                [ position relative
                , width <| pct 100
                ]
            ]
            [ viewPasswordVisibilityButton shared model.passwordIsVisible SwitchPasswordVisibility
            , input
                [ Attr.placeholder <| passwordInputPlaceholder shared.language
                , Attr.maxlength Password.maxLen
                , Attr.type_ <|
                    if model.passwordIsVisible then
                        "text"

                    else
                        "password"
                , Attr.value model.password
                , Ev.onInput PasswordChanged
                , css <| inputStyle shared isPasswordError
                ]
                []
            ]
        , div
            [ css
                [ displayFlex
                , alignItems center
                , property "gap" "0.5rem"
                ]
            ]
            [ input
                [ Attr.type_ "checkbox"
                , Attr.checked model.rememberMe
                , Ev.onCheck RememberMeChanged
                , css
                    [ backgroundColor shared.theme.mainColor
                    , outline none
                    , borderStyle none
                    , cursor pointer
                    ]
                ]
                []
            , span
                [ css
                    [ fontSize shared.theme.mediumFontSize
                    , color shared.theme.mainFontColor
                    ]
                ]
                [ text <| rememberMeText shared.language ]
            ]
        , viewSignInButton shared model.status
        ]


signInButtonText : Language -> String
signInButtonText language =
    case language of
        English ->
            "Sign In"

        Ukrainian ->
            "Увійти"


signInSuccessText : Language -> String
signInSuccessText language =
    case language of
        English ->
            "Successfully signed in"

        Ukrainian ->
            "Успішна авторизація"


signInLoadingText : Language -> String
signInLoadingText language =
    case language of
        English ->
            "Loading..."

        Ukrainian ->
            "Авторизація..."


viewSignInButton : Shared.Model -> Status () Error -> Html Msg
viewSignInButton shared status =
    case status of
        Idle ->
            button
                [ Ev.onClick SignInClicked
                , css <| buttonStyle shared
                ]
                [ text <| signInButtonText shared.language ]

        Loading ->
            messageSpan shared <| signInLoadingText shared.language

        Success _ ->
            successMessageSpan shared <| signInSuccessText shared.language

        Error error ->
            errorMessageSpan shared <| translateError shared.language error
