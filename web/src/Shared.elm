module Shared exposing
    ( Flags
    , Model
    , Msg(..)
    , init
    , subscriptions
    , update
    )

import Api.Reauth as Reauth
import Api.SignIn exposing (User(..))
import Api.User as User
import Browser.Navigation as Nav
import Http
import Json.Decode as Json
import Language exposing (Language)
import LocalStorage exposing (LocalStorage)
import Ports
import Request exposing (Request)
import Task
import Theme exposing (Theme)
import Time


type alias Flags =
    Json.Value


type alias Model =
    { localStorage : LocalStorage
    , languageIds : List Int
    , tagIds : List Int
    , language : Language
    , theme : Theme
    , user : User
    , zone : Time.Zone
    , now : Time.Posix
    , isMenuOpen : Bool
    }


type Msg
    = GotLocalStorage LocalStorage
    | Reauth
    | GotReauthResponse (Result Http.Error User)
    | Auth
        Bool
        { token : String
        , retoken : String
        , userMeta : User.Meta
        }
    | GotZone Time.Zone
    | GotNow Time.Posix
    | Redirect String
    | MenuClicked


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    let
        localStorage =
            LocalStorage.decode flags

        model =
            { localStorage = localStorage
            , languageIds = localStorage.languageIds
            , tagIds = localStorage.tagIds
            , language = Language.default
            , theme = Theme.default
            , user = Unauthorized
            , zone = Time.utc
            , now = Time.millisToPosix 0
            , isMenuOpen = False
            }

        cmd =
            Cmd.batch
                [ Task.perform GotZone Time.here
                , Task.perform GotNow Time.now
                , case localStorage.retoken of
                    Just retoken ->
                        Reauth.request { retoken = retoken } GotReauthResponse

                    Nothing ->
                        Cmd.none
                ]
    in
    ( model, cmd )


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        GotLocalStorage localStorage ->
            ( { model | localStorage = localStorage }, Cmd.none )

        Reauth ->
            case model.user of
                Unauthorized ->
                    ( model, Nav.pushUrl req.key "/sign-in" )

                Authorized authorizedUser ->
                    ( model, Reauth.request { retoken = authorizedUser.retoken } GotReauthResponse )

        GotReauthResponse httpResponse ->
            case httpResponse of
                Ok Unauthorized ->
                    let
                        localStorage =
                            model.localStorage

                        newLocalStorage =
                            { localStorage | retoken = Nothing }

                        cmds =
                            Cmd.batch
                                [ LocalStorage.setLocalStorage newLocalStorage
                                , Nav.pushUrl req.key "/sign-in"
                                ]
                    in
                    ( model, cmds )

                Ok (Authorized authorizedUser) ->
                    let
                        localStorage =
                            model.localStorage

                        newLocalStorage =
                            { localStorage | retoken = Just authorizedUser.retoken }

                        cmds =
                            Cmd.batch
                                [ LocalStorage.setLocalStorage newLocalStorage
                                , Ports.triggerRetry ()
                                ]
                    in
                    ( { model | user = Authorized authorizedUser }, cmds )

                Err _ ->
                    let
                        localStorage =
                            model.localStorage

                        newLocalStorage =
                            { localStorage | retoken = Nothing }

                        cmds =
                            Cmd.batch
                                [ LocalStorage.setLocalStorage newLocalStorage
                                , Nav.pushUrl req.key "/sign-in"
                                ]
                    in
                    ( model, cmds )

        Auth rememberMe authorizedUser ->
            let
                localStorage =
                    model.localStorage

                newLocalStorage =
                    if rememberMe then
                        { localStorage | retoken = Just authorizedUser.retoken }

                    else
                        localStorage

                cmds =
                    Cmd.batch
                        [ LocalStorage.setLocalStorage newLocalStorage
                        , Nav.pushUrl req.key "/"
                        ]
            in
            ( { model | user = Authorized authorizedUser }, cmds )

        GotZone zone ->
            ( { model | zone = zone }, Cmd.none )

        GotNow now ->
            ( { model | now = now }, Cmd.none )

        Redirect path ->
            ( model, Nav.pushUrl req.key path )

        MenuClicked ->
            ( { model | isMenuOpen = not model.isMenuOpen }, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch
        [ LocalStorage.getLocalStorage GotLocalStorage

        -- , Time.every 1000 GotNow
        ]
