module Pages.Post.Edit.PostContentId_ exposing (Model, Msg, page)

import Api.Post.Edit as PostEdit
import Api.Post.Edit.Languages as PostEditLangauges
import Api.Post.Fetch as PostFetch
import Api.SignIn exposing (User(..), getToken)
import Effect exposing (Effect)
import Gen.Params.Post.Edit.PostContentId_ exposing (Params)
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
        postContentId =
            Maybe.withDefault 0 <| String.toInt req.params.postContentId
    in
    Page.advanced
        { init = init postContentId shared
        , update = update postContentId shared
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type Error
    = PostNotFound
    | ServerError


type alias Model =
    { postStatus : Status () Error
    , postFormModel : PostForm.Model
    }


init : Int -> Shared.Model -> ( Model, Effect Msg )
init postContentId shared =
    let
        ( postFormModel, postFormEff ) =
            PostForm.init <| fetchLanguages postContentId

        model =
            { postStatus = Loading
            , postFormModel = postFormModel
            }

        effs =
            Effect.batch
                [ fetchPost postContentId shared
                , Effect.map PostFormMsg postFormEff
                ]
    in
    ( model, effs )



-- UPDATE


type Msg
    = Retry
    | GotPostResponse (Result Http.Error PostFetch.Response)
    | GotEditResponse (Result Http.Error PostEdit.Response)
    | PostFormMsg PostForm.Msg


update : Int -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update postContentId shared msg model =
    case msg of
        Retry ->
            if model.postFormModel.status == Loading then
                ( model, sendRequest postContentId shared model )

            else
                ( model, fetchPost postContentId shared )

        GotPostResponse httpResponse ->
            case httpResponse of
                Ok PostFetch.Unauthorized ->
                    ( model, reauth )

                Ok (PostFetch.Success (Just post)) ->
                    let
                        postFormModel =
                            model.postFormModel

                        newPostFormModel =
                            { postFormModel | selectedLanguage = Just { id = post.languageId, name = post.language }, title = post.title, description = post.description, tags = Set.fromList post.tags, content = post.content }
                    in
                    ( { model | postStatus = Success (), postFormModel = newPostFormModel }, Effect.none )

                Ok (PostFetch.Success Nothing) ->
                    ( { model | postStatus = Error PostNotFound }, Effect.none )

                Err _ ->
                    ( { model | postStatus = Error ServerError }, Effect.none )

        GotEditResponse httpResponse ->
            case httpResponse of
                Ok PostEdit.Unauthorized ->
                    ( model, reauth )

                Ok PostEdit.Success ->
                    ( model, Effect.fromShared <| Shared.Redirect <| "/post/" ++ String.fromInt postContentId )

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
                    ( { model | postFormModel = newPostFormModel }, sendRequest postContentId shared model )

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


fetchPost : Int -> Shared.Model -> Effect Msg
fetchPost postContentId shared =
    let
        token =
            getToken shared.user
    in
    Effect.fromCmd <| PostFetch.request { token = token, postContentId = postContentId } GotPostResponse


sendRequest : Int -> Shared.Model -> Model -> Effect Msg
sendRequest postContentId shared model =
    case shared.user of
        Unauthorized ->
            reauth

        Authorized authorizedUser ->
            case model.postFormModel.selectedLanguage of
                Just language ->
                    let
                        req =
                            { token = authorizedUser.token
                            , postContentId = postContentId
                            , languageId = language.id
                            , title = model.postFormModel.title
                            , description = model.postFormModel.description
                            , tags = Set.toList model.postFormModel.tags
                            , content = model.postFormModel.content
                            }
                    in
                    Effect.fromCmd <| PostEdit.request req GotEditResponse

                Nothing ->
                    Effect.none


fetchLanguages : Int -> String -> (Result Http.Error (List PostForm.ApiLanguage) -> msg) -> Cmd msg
fetchLanguages postContentId query gotResponse =
    let
        req =
            { postContentId = postContentId
            , query = query
            }
    in
    PostEditLangauges.request req gotResponse
