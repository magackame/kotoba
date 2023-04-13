module Pages.Post.Create exposing (Model, Msg, page)

import Api.Languages.Fetch as LanguagesFetch
import Api.Post.Create as PostCreate
import Api.SignIn exposing (User(..))
import Css exposing (..)
import Effect exposing (Effect)
import Gen.Params.Post.Create exposing (Params)
import Html.Styled exposing (..)
import Http
import Language exposing (Language(..))
import Page
import Ports
import Reauth exposing (reauth)
import Request
import Set
import Shared
import Shared.View.PostForm as PostForm
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


type alias Model =
    { postFormModel : PostForm.Model
    }


init : ( Model, Effect Msg )
init =
    let
        ( postFormModel, postFormEff ) =
            PostForm.init fetchLanguages

        model =
            { postFormModel = postFormModel
            }
    in
    ( model, Effect.map PostFormMsg postFormEff )



-- UPDATE


type Msg
    = Retry
    | GotCreateResponse (Result Http.Error PostCreate.Response)
    | PostFormMsg PostForm.Msg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        Retry ->
            if model.postFormModel.status == Loading then
                ( model, sendRequest shared model )

            else
                ( model, Effect.none )

        GotCreateResponse httpResponse ->
            case httpResponse of
                Ok PostCreate.Unauthorized ->
                    ( model, reauth )

                Ok (PostCreate.Success postContentId) ->
                    let
                        postFormModel =
                            model.postFormModel

                        newPostFormModel =
                            { postFormModel | status = Success () }
                    in
                    ( { model | postFormModel = newPostFormModel }, Effect.fromShared <| Shared.Redirect <| "/post/" ++ String.fromInt postContentId )

                Err _ ->
                    let
                        postFormModel =
                            model.postFormModel

                        newPostFormModel =
                            { postFormModel | status = Error PostForm.ServerError }
                    in
                    ( { model | postFormModel = newPostFormModel }, Effect.none )

        PostFormMsg postFormMsg ->
            case postFormMsg of
                PostForm.SendClicked ->
                    let
                        postFormModel =
                            model.postFormModel

                        newPostFormModel =
                            { postFormModel | status = Loading }
                    in
                    ( { model | postFormModel = newPostFormModel }, sendRequest shared model )

                _ ->
                    let
                        ( postFormModel, postFormEff ) =
                            PostForm.update postFormMsg model.postFormModel
                    in
                    ( { model | postFormModel = postFormModel }, Effect.map PostFormMsg postFormEff )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.retry (\_ -> Retry)



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    View.map PostFormMsg <| PostForm.view shared model.postFormModel


sendRequest : Shared.Model -> Model -> Effect Msg
sendRequest shared model =
    case shared.user of
        Unauthorized ->
            reauth

        Authorized authorizedUser ->
            case model.postFormModel.selectedLanguage of
                Just language ->
                    let
                        request =
                            { token = authorizedUser.token
                            , languageId = language.id
                            , title = model.postFormModel.title
                            , description = model.postFormModel.description
                            , tags = Set.toList model.postFormModel.tags
                            , content = model.postFormModel.content
                            }
                    in
                    Effect.fromCmd <| PostCreate.request request GotCreateResponse

                Nothing ->
                    Effect.none


fetchLanguages : String -> (Result Http.Error (List PostForm.ApiLanguage) -> PostForm.Msg) -> Cmd PostForm.Msg
fetchLanguages query gotResponse =
    let
        req =
            { query = query
            }
    in
    LanguagesFetch.request req gotResponse
