module Pages.SignUp exposing (Model, Msg, page)

import Api.Email as Email
import Api.Handle as Handle
import Api.Password as Password
import Api.SignUp as SignUp
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
import Page
import Request
import Shared
import Shared.View.Sign exposing (..)
import Status exposing (Status(..))
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init req.key
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type Error
    = EmailIsRequired
    | EmailAlreadyTaken
    | InvalidEmail
    | HandleIsRequired
    | HandleAlreadyTaken
    | InvalidHandle
    | PasswordIsRequired
    | PasswordIsTooShort
    | PasswordsDoNotMatch
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

        EmailAlreadyTaken ->
            case language of
                English ->
                    "Email is already taken"

                Ukrainian ->
                    "Така електронна пошта вже зайнята"

        InvalidEmail ->
            case language of
                English ->
                    "Invalid email"

                Ukrainian ->
                    "Невірна електронна пошта"

        HandleIsRequired ->
            case language of
                English ->
                    "Enter your handle"

                Ukrainian ->
                    "Введіть нік"

        HandleAlreadyTaken ->
            case language of
                English ->
                    "Handle is already taken"

                Ukrainian ->
                    "Такий нік вже зайнятий"

        InvalidHandle ->
            case language of
                English ->
                    "Handle must satisfy " ++ Handle.regex

                Ukrainian ->
                    "Нік повинен відповідати " ++ Handle.regex

        PasswordIsRequired ->
            case language of
                English ->
                    "Enter your password"

                Ukrainian ->
                    "Введіть пароль"

        PasswordIsTooShort ->
            case language of
                English ->
                    "Password must be at least " ++ String.fromInt Password.minLen ++ " characters long"

                Ukrainian ->
                    "Пароль має бути як мінімум " ++ String.fromInt Password.minLen ++ " символів у довжину"

        PasswordsDoNotMatch ->
            case language of
                English ->
                    "Passwords do not match"

                Ukrainian ->
                    "Паролі не збігаються"

        ServerError ->
            case language of
                English ->
                    "Server error"

                Ukrainian ->
                    "Помилка на сервері"


type alias Model =
    { key : Key
    , email : String
    , handle : String
    , password : String
    , passwordRepeat : String
    , passwordIsVisible : Bool
    , status : Status () Error
    }


init : Key -> ( Model, Effect Msg )
init key =
    ( validate { key = key, email = "", handle = "", password = "", passwordRepeat = "", passwordIsVisible = False, status = Idle }, Effect.none )



-- UPDATE


type Msg
    = EmailChanged String
    | HandleChanged String
    | PasswordChanged String
    | PasswordRepeatChanged String
    | SwitchPasswordVisibility
    | SignUpClicked
    | GotSignUpResponse (Result Http.Error SignUp.Response)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        EmailChanged email ->
            let
                newModel =
                    { model | email = email }
            in
            ( validate newModel, Effect.none )

        HandleChanged handle ->
            let
                newModel =
                    { model | handle = handle }
            in
            ( validate newModel, Effect.none )

        PasswordChanged password ->
            let
                newModel =
                    { model | password = password }
            in
            ( validate newModel, Effect.none )

        PasswordRepeatChanged passwordRepeat ->
            let
                newModel =
                    { model | passwordRepeat = passwordRepeat }
            in
            ( validate newModel, Effect.none )

        SwitchPasswordVisibility ->
            ( { model | passwordIsVisible = not model.passwordIsVisible }, Effect.none )

        SignUpClicked ->
            let
                -- TODO: Hash password
                req =
                    { handle = model.handle
                    , email = model.email
                    , password = model.password
                    }
            in
            ( { model | status = Loading }, Effect.fromCmd <| SignUp.request req GotSignUpResponse )

        GotSignUpResponse httpResponse ->
            case httpResponse of
                Ok response ->
                    case response of
                        SignUp.HandleAlreadyTaken ->
                            ( { model | status = Error HandleAlreadyTaken }, Effect.none )

                        SignUp.EmailAlreadyTaken ->
                            ( { model | status = Error EmailAlreadyTaken }, Effect.none )

                        SignUp.InvalidEmail ->
                            ( { model | status = Error InvalidEmail }, Effect.none )

                        SignUp.Success ->
                            ( { model | status = Success () }, Effect.fromCmd <| Nav.pushUrl model.key "/sign-in" )

                Err _ ->
                    Debug.log "ERROR"
                        ( { model | status = Error ServerError }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
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
                        , width <| calc (pct 100) minus (rem 2)
                        , maxWidth <| ch 80
                        ]
                    ]
                    [ viewSignInForm shared model
                    ]
                ]
            ]
    }


validate : Model -> Model
validate model =
    if String.isEmpty model.email then
        { model | status = Error EmailIsRequired }

    else if String.isEmpty model.handle then
        { model | status = Error HandleIsRequired }

    else if not <| Handle.isValid model.handle then
        { model | status = Error InvalidHandle }

    else if String.isEmpty model.password then
        { model | status = Error PasswordIsRequired }

    else if String.length model.password < Password.minLen then
        { model | status = Error PasswordIsTooShort }

    else if model.password /= model.passwordRepeat then
        { model | status = Error PasswordsDoNotMatch }

    else
        { model | status = Idle }


viewSignInForm : Shared.Model -> Model -> Html Msg
viewSignInForm shared model =
    let
        isEmailError =
            case model.status of
                Error EmailIsRequired ->
                    True

                Error EmailAlreadyTaken ->
                    True

                Error InvalidEmail ->
                    True

                _ ->
                    False

        isHandleError =
            case model.status of
                Error HandleIsRequired ->
                    True

                Error HandleAlreadyTaken ->
                    True

                Error InvalidHandle ->
                    True

                _ ->
                    False

        isPasswordError =
            case model.status of
                Error PasswordIsRequired ->
                    True

                Error PasswordIsTooShort ->
                    True

                _ ->
                    False

        isPasswordRepeatError =
            case model.status of
                Error PasswordsDoNotMatch ->
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
        , input
            [ Attr.placeholder <| handleInputPlaceholder shared.language
            , Attr.maxlength Handle.maxLen
            , Attr.value model.handle
            , Ev.onInput HandleChanged
            , css <| inputStyle shared isHandleError
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
                [ position relative
                , width <| pct 100
                ]
            ]
            [ viewPasswordVisibilityButton shared model.passwordIsVisible SwitchPasswordVisibility
            , input
                [ Attr.placeholder <| passwordRepeatInputPlaceholder shared.language
                , Attr.maxlength Password.maxLen
                , Attr.type_ <|
                    if model.passwordIsVisible then
                        "text"

                    else
                        "password"
                , Attr.value model.passwordRepeat
                , Ev.onInput PasswordRepeatChanged
                , css <| inputStyle shared isPasswordRepeatError
                ]
                []
            ]
        , viewSignUpButton shared model.status
        ]


handleInputPlaceholder : Language -> String
handleInputPlaceholder language =
    case language of
        English ->
            "Handle"

        Ukrainian ->
            "Нік"


passwordRepeatInputPlaceholder : Language -> String
passwordRepeatInputPlaceholder language =
    case language of
        English ->
            "Password repeat"

        Ukrainian ->
            "Повторіть пароль"


signUpButtonText : Language -> String
signUpButtonText language =
    case language of
        English ->
            "Sign Up"

        Ukrainian ->
            "Зареєструватися"


signUpSuccessText : Language -> String
signUpSuccessText language =
    case language of
        English ->
            "Successfully signed up"

        Ukrainian ->
            "Успішна реєстрація"


signUpLoadingText : Language -> String
signUpLoadingText language =
    case language of
        English ->
            "Loading..."

        Ukrainian ->
            "Реєстрація..."


viewSignUpButton : Shared.Model -> Status () Error -> Html Msg
viewSignUpButton shared status =
    case status of
        Idle ->
            button
                [ Ev.onClick SignUpClicked
                , css <| buttonStyle shared
                ]
                [ text <| signUpButtonText shared.language ]

        Loading ->
            messageSpan shared <| signUpLoadingText shared.language

        Success _ ->
            successMessageSpan shared <| signUpSuccessText shared.language

        Error error ->
            errorMessageSpan shared <| translateError shared.language error
