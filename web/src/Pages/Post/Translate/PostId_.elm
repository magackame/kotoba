module Pages.Post.Translate.PostId_ exposing (Model, Msg, page)

import Api.Post.Translate as PostTranslate
import Api.Post.Translate.Languages as TranslateLanguages
import Api.SignIn exposing (User(..))
import Effect exposing (Effect)
import Gen.Params.Post.Translate.PostId_ exposing (Params)
import Http
import Page
import Ports
import Reauth exposing (reauth)
import Request
import Set
import Shared
import Shared.View.PostForm as PostForm
import Status exposing (Status(..))
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    let
        postId =
            Maybe.withDefault 0 <| String.toInt req.params.postId
    in
    Page.advanced
        { init = init postId
        , update = update postId shared
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { postFormModel : PostForm.Model
    }


init : Int -> ( Model, Effect Msg )
init postId =
    let
        ( postFormModel, postFormEff ) =
            PostForm.init <| fetchLanguages postId

        model =
            { postFormModel = postFormModel
            }
    in
    ( model, Effect.map PostFormMsg postFormEff )



-- UPDATE


type Msg
    = Retry
    | GotTranslateResponse (Result Http.Error PostTranslate.Response)
    | PostFormMsg PostForm.Msg


update : Int -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update postId shared msg model =
    case msg of
        Retry ->
            case model.postFormModel.status of
                Loading ->
                    ( model, sendRequest postId shared model )

                _ ->
                    ( model, Effect.none )

        GotTranslateResponse httpResponse ->
            case httpResponse of
                Ok PostTranslate.Unauthorized ->
                    ( model, reauth )

                Ok (PostTranslate.Success postContentId) ->
                    ( model, Effect.fromShared <| Shared.Redirect <| "/post/" ++ String.fromInt postContentId )

                Err error ->
                    let
                        debug =
                            Debug.log "ERROR" error

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
                    ( { model | postFormModel = newPostFormModel }, sendRequest postId shared model )

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


fetchLanguages : Int -> String -> (Result Http.Error (List PostForm.ApiLanguage) -> PostForm.Msg) -> Cmd PostForm.Msg
fetchLanguages postId query gotResponse =
    let
        req =
            { postId = postId
            , query = query
            }
    in
    TranslateLanguages.request req gotResponse


sendRequest : Int -> Shared.Model -> Model -> Effect Msg
sendRequest postId shared model =
    case shared.user of
        Unauthorized ->
            reauth

        Authorized authorizedUser ->
            case model.postFormModel.selectedLanguage of
                Just language ->
                    let
                        request =
                            { token = authorizedUser.token
                            , postId = postId
                            , languageId = language.id
                            , title = model.postFormModel.title
                            , description = model.postFormModel.description
                            , tags = Set.toList model.postFormModel.tags
                            , content = model.postFormModel.content
                            }
                    in
                    Effect.fromCmd <| PostTranslate.request request GotTranslateResponse

                Nothing ->
                    Effect.none
