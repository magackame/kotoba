module Pages.Post.Id_ exposing (Model, Msg, page)

import Api.Comment as Comment exposing (Comment)
import Api.Post as Post exposing (Post)
import Api.Post.Bookmarks as PostBookmarks
import Api.Post.Comments.Create as PostCommentsCreate
import Api.Post.Comments.Fetch as PostCommentsFetch
import Api.Post.Fetch as PostFetch
import Api.Post.Translations as PostTranslations
import Api.SignIn exposing (User(..), getToken)
import Api.Translation exposing (Translation)
import Css exposing (..)
import Css.Transitions as Transitions
import Dict
import Effect exposing (Effect)
import Gen.Params.Post.Id_ exposing (Params)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Ev
import Http
import Language exposing (Language(..), translateMonth)
import Page
import Ports
import Reauth exposing (reauth)
import Request
import Shared
import Shared.View.Comment exposing (replyToStyle, viewComment, viewComments)
import Shared.View.Layout exposing (viewMenu)
import Shared.View.Post.CommentCreateError as CommentCreateError exposing (CommentCreateError)
import Shared.View.PostedBy exposing (smallTextSpan, viewPostedBy, viewPostedByProfilePicture)
import Shared.View.Sign exposing (errorMessageSpan, inputStyle, messageSpan)
import Shared.View.Tags exposing (tagStyle, viewTags)
import Status exposing (Status(..))
import Time
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req.params.id
        , update = update req.params.id shared
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type Error
    = PostNotFound
    | EndOfContent
    | ServerError


type alias Model =
    { status : Status Post Error
    , isHoveringOverBookmarkButton : Bool

    -- TODO: bookmark error
    , bookmarkStatus : Status () Error
    , isBookmarked : Bool
    , commentCreateStatus : Status () CommentCreateError
    , replyCreateStatus : Status () CommentCreateError
    , search : String
    , limit : Int
    , offset : Int
    , commentContent : String
    , replyTo : Maybe Int
    , replyContent : String
    , commentsStatus : Status () Error
    , comments : List Comment
    , scrollFromId : Maybe String
    }


init : Shared.Model -> String -> ( Model, Effect Msg )
init shared id =
    let
        model =
            { status = Loading
            , isHoveringOverBookmarkButton = False
            , bookmarkStatus = Idle
            , isBookmarked = False
            , commentCreateStatus = Idle
            , replyCreateStatus = Idle
            , search = ""
            , limit = 20
            , offset = 0
            , commentContent = ""
            , replyTo = Nothing
            , replyContent = ""
            , commentsStatus = Loading
            , comments = []
            , scrollFromId = Nothing
            }

        effs =
            Effect.batch
                [ fetchPost id shared
                , fetchComments id model
                ]
    in
    ( model, effs )



-- UPDATE


type Msg
    = GotPostResponse (Result Http.Error PostFetch.Response)
    | Retry
    | MenuClicked
    | IsHoveringOverBookmarkButtonChanged Bool
    | BookmarkClicked
    | GotBookmarkResponse (Result Http.Error PostBookmarks.Response)
    | ScrollTo String String
    | ScrollBack
    | CommentContentChanged String
    | ReplyClicked Int
    | ReplyContentChanged String
    | SearchChanged String
    | SendComment
    | SendReply
    | EndOfPageReached
    | GotCommentsCreateResponse (Result Http.Error PostCommentsCreate.Response)
    | GotReplyCreateResponse (Result Http.Error PostCommentsCreate.Response)
    | GotCommentsResponse (Result Http.Error (List Comment))


update : String -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update id shared msg model =
    case msg of
        GotPostResponse httpResponse ->
            case httpResponse of
                Ok PostFetch.Unauthorized ->
                    ( model, reauth )

                Ok (PostFetch.Success (Just post)) ->
                    ( { model | status = Success post, isBookmarked = post.isBookmarked }, Effect.none )

                Ok (PostFetch.Success Nothing) ->
                    ( { model | status = Error PostNotFound }, Effect.none )

                Err _ ->
                    ( { model | status = Error ServerError }, Effect.none )

        Retry ->
            let
                eff =
                    if model.bookmarkStatus == Loading then
                        sendBookmarksRequest shared model

                    else if model.commentCreateStatus == Loading then
                        sendCommentsCreateRequest id shared model

                    else if model.replyCreateStatus == Loading then
                        sendReplyCreateRequest id shared model

                    else
                        fetchPost id shared
            in
            ( model, eff )

        MenuClicked ->
            ( model, Effect.fromShared Shared.MenuClicked )

        IsHoveringOverBookmarkButtonChanged isHoveringOverBookmarkButton ->
            ( { model | isHoveringOverBookmarkButton = isHoveringOverBookmarkButton }, Effect.none )

        BookmarkClicked ->
            ( { model | bookmarkStatus = Loading }, sendBookmarksRequest shared model )

        GotBookmarkResponse httpResponse ->
            case httpResponse of
                Ok PostBookmarks.Unauthorized ->
                    ( model, reauth )

                Ok PostBookmarks.Success ->
                    ( { model | bookmarkStatus = Success (), isBookmarked = not model.isBookmarked }, Effect.none )

                Err _ ->
                    ( { model | bookmarkStatus = Error ServerError }, Effect.none )

        ScrollTo scrollFromId scrollToId ->
            ( { model | scrollFromId = Just scrollFromId }, Effect.fromCmd <| Ports.scrollTo scrollToId )

        ScrollBack ->
            case model.scrollFromId of
                Just scrollFromId ->
                    ( { model | scrollFromId = Nothing }, Effect.fromCmd <| Ports.scrollTo scrollFromId )

                Nothing ->
                    ( model, Effect.none )

        CommentContentChanged content ->
            ( { model | commentContent = content }, Effect.none )

        ReplyClicked replyTo ->
            ( { model | replyTo = Just replyTo, replyContent = "" }, Effect.none )

        ReplyContentChanged content ->
            ( { model | replyContent = content }, Effect.none )

        SearchChanged search ->
            let
                newModel =
                    { model | commentsStatus = Loading, comments = [], search = search, offset = 0 }
            in
            ( newModel, fetchComments id newModel )

        SendComment ->
            ( { model | commentCreateStatus = Loading }, sendCommentsCreateRequest id shared model )

        SendReply ->
            ( { model | replyCreateStatus = Loading }, sendReplyCreateRequest id shared model )

        EndOfPageReached ->
            case model.commentsStatus of
                Idle ->
                    ( { model | commentsStatus = Loading }, fetchComments id model )

                Success _ ->
                    ( { model | commentsStatus = Loading }, fetchComments id model )

                _ ->
                    ( model, Effect.none )

        GotCommentsCreateResponse httpResponse ->
            case httpResponse of
                Ok PostCommentsCreate.Unauthorized ->
                    ( model, reauth )

                Ok PostCommentsCreate.Success ->
                    ( { model | commentCreateStatus = Success (), commentContent = "" }, Effect.none )

                Err _ ->
                    ( { model | commentCreateStatus = Error CommentCreateError.ServerError }, Effect.none )

        GotReplyCreateResponse httpResponse ->
            case httpResponse of
                Ok PostCommentsCreate.Unauthorized ->
                    ( model, reauth )

                Ok PostCommentsCreate.Success ->
                    ( { model | replyCreateStatus = Success (), replyTo = Nothing, replyContent = "" }, Effect.none )

                Err _ ->
                    ( { model | replyCreateStatus = Error CommentCreateError.ServerError }, Effect.none )

        GotCommentsResponse httpResponse ->
            case httpResponse of
                Ok data ->
                    if List.isEmpty data || List.length data < model.limit then
                        ( { model | commentsStatus = Error EndOfContent, comments = model.comments ++ data, offset = model.offset + model.limit }, Effect.none )

                    else
                        ( { model | commentsStatus = Success (), comments = model.comments ++ data, offset = model.offset + model.limit }, Effect.none )

                Err _ ->
                    ( { model | commentsStatus = Error ServerError }, Effect.none )



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
                        , padding2 (rem 2) (rem 0.5)
                        , width <| calc (pct 100) minus (rem 1)
                        , maxWidth <| ch 80
                        , property "gap" "2rem"
                        ]
                    ]
                    [ viewScrollBackButton model.scrollFromId
                    , viewPost shared model
                    , viewCommentInput shared model.commentCreateStatus model.commentContent CommentContentChanged SendComment
                    , input
                        [ Attr.value model.search
                        , Attr.placeholder <| searchPlaceholder shared.language
                        , Ev.onInput SearchChanged
                        , css <| inputStyle shared False
                        ]
                        []
                    , viewComments (viewCommentWithReply shared model.replyCreateStatus model.replyTo model.replyContent) model.comments
                    ]
                ]
            ]
    }


viewPost : Shared.Model -> Model -> Html Msg
viewPost shared model =
    case model.status of
        Idle ->
            text "IDLE"

        Loading ->
            span
                [ css
                    [ fontSize shared.theme.largeFontSize
                    , color shared.theme.mainFontColor
                    , textAlign center
                    ]
                ]
                [ text <| loadingText shared.language ]

        Success post ->
            div
                [ css
                    [ displayFlex
                    , flexDirection column
                    ]
                ]
                [ div
                    [ css
                        [ displayFlex
                        , flexDirection column
                        , marginBottom <| rem 2
                        , property "gap" "1rem"
                        ]
                    ]
                    [ div
                        [ css
                            [ displayFlex
                            , justifyContent spaceBetween
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
                            [ viewPostedByProfilePicture post.postedBy
                            , let
                                postedAt =
                                    Time.millisToPosix post.postedAt

                                day =
                                    Time.toDay shared.zone postedAt

                                month =
                                    Time.toMonth shared.zone postedAt

                                year =
                                    Time.toYear shared.zone postedAt

                                formatted =
                                    translateMonth shared.language month ++ " " ++ String.fromInt day ++ " · " ++ String.fromInt year
                              in
                              viewPostedBy shared True post.postedBy (smallTextSpan shared formatted)
                            ]
                        , viewBookmarkButton shared model
                        ]
                    , viewTags True (\tag -> span [ css <| tagStyle shared ] [ text tag ]) post.tags
                    , viewTranslations shared post
                    ]
                , span
                    [ css
                        [ fontSize shared.theme.largeFontSize
                        , fontWeight bold
                        , color shared.theme.mainFontColor
                        , marginBottom <| rem 1
                        ]
                    ]
                    [ text post.title ]
                , span
                    [ css
                        [ fontSize shared.theme.contentFontSize
                        , color shared.theme.accentFontColor
                        , marginBottom <| rem 2
                        ]
                    ]
                    [ text post.description ]
                , span
                    [ css
                        [ fontSize shared.theme.contentFontSize
                        , lineHeight shared.theme.lineHeight
                        , color shared.theme.mainFontColor
                        ]
                    ]
                    [ text post.content ]
                ]

        Error _ ->
            text "ERROR"


replyInputPlaceholder : Language -> String
replyInputPlaceholder language =
    case language of
        English ->
            "What do you think?"

        Ukrainian ->
            "А вот мені здається..."


replySendButtonText : Language -> String
replySendButtonText language =
    case language of
        English ->
            "Send"

        Ukrainian ->
            "Відправити"


replyButtonText : Language -> String
replyButtonText language =
    case language of
        English ->
            "Reply"

        Ukrainian ->
            "Відповісти"


viewInputArea : Shared.Model -> String -> (String -> msg) -> Html msg
viewInputArea shared content onInput =
    textarea
        [ Attr.rows 5
        , Attr.placeholder <| replyInputPlaceholder shared.language
        , Attr.value content
        , Attr.maxlength Comment.contentMaxLen
        , Ev.onInput onInput
        , css
            [ outline none
            , padding2 (rem 1) (pct 2)
            , borderRadius <| rem 1
            , borderStyle none
            , backgroundColor shared.theme.accentColor
            , fontSize shared.theme.contentFontSize
            , color shared.theme.accentFontColor
            , resize none
            , width <| pct 96
            ]
        ]
        []


viewCommentInput : Shared.Model -> Status () CommentCreateError -> String -> (String -> msg) -> msg -> Html msg
viewCommentInput shared replyCreateStatus content onInput onClick =
    let
        b =
            button
                [ Ev.onClick onClick
                , css
                    [ outline none
                    , padding <| rem 0.5
                    , borderRadius <| rem 0.5
                    , borderStyle none
                    , fontSize shared.theme.mediumFontSize
                    , fontWeight bold
                    , backgroundColor shared.theme.mainColor
                    , color shared.theme.accentFontColor
                    , cursor pointer
                    , Transitions.transition
                        [ Transitions.backgroundColor3 420 0 Transitions.easeIn
                        ]
                    , hover
                        [ backgroundColor transparent
                        ]
                    ]
                ]
                [ text <| replySendButtonText shared.language ]
    in
    case shared.user of
        Unauthorized ->
            text ""

        Authorized _ ->
            div
                [ css
                    [ displayFlex
                    , flexDirection column
                    , alignItems end
                    , property "gap" "1rem"
                    , width <| pct 100
                    ]
                ]
                [ viewInputArea shared content onInput
                , case replyCreateStatus of
                    -- TODO:
                    Idle ->
                        b

                    Loading ->
                        messageSpan shared <| commentCreateLoadingText shared.language

                    Success _ ->
                        b

                    Error error ->
                        errorMessageSpan shared <| CommentCreateError.translate shared.language error
                ]


viewCommentWithReply : Shared.Model -> Status () CommentCreateError -> Maybe Int -> String -> Comment -> Html Msg
viewCommentWithReply shared replyCreateStatus modelReplyTo commentReplyContent comment =
    let
        reply =
            case shared.user of
                Unauthorized ->
                    text ""

                Authorized _ ->
                    div
                        [ css
                            [ displayFlex
                            , justifyContent right
                            ]
                        ]
                        [ case modelReplyTo of
                            Just id ->
                                if id == comment.id then
                                    viewCommentInput shared replyCreateStatus commentReplyContent ReplyContentChanged SendReply

                                else
                                    viewReplyButton shared comment.id

                            Nothing ->
                                viewReplyButton shared comment.id
                        ]
    in
    viewComment shared (viewReplyTo shared comment.id comment.replyTo) reply comment


viewReplyTo : Shared.Model -> Int -> Maybe Comment.Reply -> Html Msg
viewReplyTo shared commentId replyTo =
    case replyTo of
        Just meta ->
            button
                [ Ev.onClick <| ScrollTo (String.fromInt commentId) (String.fromInt meta.commentId)
                , css <| replyToStyle shared
                ]
                [ text <| "↳ " ++ meta.replyTo.handle ]

        Nothing ->
            text ""


viewReplyButton : Shared.Model -> Int -> Html Msg
viewReplyButton shared replyTo =
    button
        [ Ev.onClick <| ReplyClicked replyTo
        , css
            [ outline none
            , padding <| rem 0.5
            , borderRadius <| rem 0.5
            , borderStyle none
            , fontSize shared.theme.mediumFontSize
            , fontWeight bold
            , backgroundColor shared.theme.accentColor
            , color shared.theme.accentFontColor
            , cursor pointer
            , Transitions.transition
                [ Transitions.backgroundColor3 420 0 Transitions.easeIn
                , Transitions.color3 420 0 Transitions.easeIn
                ]
            , hover
                [ backgroundColor transparent
                , color shared.theme.mainFontColor
                ]
            ]
        ]
        [ text <| replyButtonText shared.language ]



-- TODO: floating button
--
-- case scrollFromId of
--     Just _ ->
--         button
--             [ Ev.onClick ScrollBack
--             , css
--                 [ position fixed
--                 , bottom <| px 10
--                 , right <| px 10
--                 ]
--             ]
--             [ text "AMIGUS" ]
--     Nothing ->
--         text ""


viewScrollBackButton : Maybe String -> Html Msg
viewScrollBackButton scrollFromId =
    text ""


viewTranslation : Shared.Model -> Int -> Translation -> Html Msg
viewTranslation shared postContentId translation =
    a
        [ Attr.href <| "/post/" ++ String.fromInt translation.postContentId
        , css
            [ color <|
                if translation.postContentId == postContentId then
                    shared.theme.mainFontColor

                else
                    shared.theme.accentFontColor
            , fontSize shared.theme.mediumFontSize
            , textDecoration none
            , borderRadius <| rem 0.5
            , padding <| rem 0.5
            , cursor pointer
            , flexShrink zero
            , Transitions.transition
                [ Transitions.backgroundColor3 420 0 Transitions.easeIn
                , Transitions.color3 420 0 Transitions.easeIn
                ]
            , hover
                [ backgroundColor transparent
                , color shared.theme.mainFontColor
                ]
            ]
        ]
        [ text translation.language ]


fetchPost : String -> Shared.Model -> Effect Msg
fetchPost id shared =
    let
        postContentId =
            Maybe.withDefault 0 <| String.toInt id

        token =
            getToken shared.user

        req =
            { token = token
            , postContentId = postContentId
            }
    in
    Effect.fromCmd <| PostFetch.request req GotPostResponse


loadingText : Language -> String
loadingText language =
    case language of
        English ->
            "Loading..."

        Ukrainian ->
            "Завантажуємо пост..."


viewTranslations : Shared.Model -> Post -> Html Msg
viewTranslations shared post =
    let
        priorities =
            Dict.fromList <| List.indexedMap (\i id -> ( id, List.length shared.languageIds - i )) shared.languageIds

        translations =
            List.map .translation <| List.sortWith translationCompare <| List.map (\t -> { priority = Maybe.withDefault 0 <| Dict.get t.languageId priorities, translation = t }) post.translations
    in
    div
        [ css
            [ displayFlex
            , flexWrap wrap
            , property "row-gap" "0.5rem"
            , property "column-gap" "1rem"
            ]
        ]
        (List.map (viewTranslation shared post.postContentId) translations)


translationCompare a b =
    case compare a.priority b.priority of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT


viewBookmarkButton : Shared.Model -> Model -> Html Msg
viewBookmarkButton shared model =
    let
        b =
            if model.isBookmarked then
                button
                    [ Ev.onMouseEnter <| IsHoveringOverBookmarkButtonChanged True
                    , Ev.onMouseLeave <| IsHoveringOverBookmarkButtonChanged False
                    , Ev.onClick BookmarkClicked
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
                        if model.isHoveringOverBookmarkButton then
                            unBookmarkButtonText shared.language

                        else
                            bookmarkedButtonText shared.language
                    ]

            else
                button
                    [ Ev.onClick BookmarkClicked
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
                    [ text <| bookmarkButtonText shared.language ]
    in
    case shared.user of
        Unauthorized ->
            text ""

        Authorized _ ->
            case model.bookmarkStatus of
                Idle ->
                    b

                Success _ ->
                    b

                Loading ->
                    text "LOADING"

                Error _ ->
                    text "ERROR"


bookmarkButtonText : Language -> String
bookmarkButtonText language =
    case language of
        English ->
            "Bookmark"

        Ukrainian ->
            "Зберігти"


bookmarkedButtonText : Language -> String
bookmarkedButtonText language =
    case language of
        English ->
            "Bookmarked"

        Ukrainian ->
            "Збережено"


unBookmarkButtonText : Language -> String
unBookmarkButtonText language =
    case language of
        English ->
            "Unbookmark"

        Ukrainian ->
            "Видалити"


sendBookmarksRequest : Shared.Model -> Model -> Effect Msg
sendBookmarksRequest shared model =
    case shared.user of
        Unauthorized ->
            reauth

        Authorized authorizedUser ->
            case model.status of
                Success post ->
                    let
                        req =
                            { token = authorizedUser.token
                            , postId = post.id
                            }
                    in
                    Effect.fromCmd <| PostBookmarks.request req GotBookmarkResponse

                _ ->
                    Effect.none


sendCommentsCreateRequest : String -> Shared.Model -> Model -> Effect Msg
sendCommentsCreateRequest id shared model =
    case ( String.toInt id, shared.user ) of
        ( Just postContentId, Authorized authorizedUser ) ->
            let
                req =
                    { token = authorizedUser.token
                    , postContentId = postContentId
                    , replyTo = Nothing
                    , content = model.commentContent
                    }
            in
            Effect.fromCmd <| PostCommentsCreate.request req GotCommentsCreateResponse

        _ ->
            reauth


sendReplyCreateRequest : String -> Shared.Model -> Model -> Effect Msg
sendReplyCreateRequest id shared model =
    case ( String.toInt id, shared.user ) of
        ( Just postContentId, Authorized authorizedUser ) ->
            let
                req =
                    { token = authorizedUser.token
                    , postContentId = postContentId
                    , replyTo = model.replyTo
                    , content = model.replyContent
                    }
            in
            Effect.fromCmd <| PostCommentsCreate.request req GotReplyCreateResponse

        _ ->
            reauth


fetchComments : String -> Model -> Effect Msg
fetchComments id model =
    case String.toInt id of
        Just postContentId ->
            let
                req =
                    { postContentId = postContentId
                    , query = model.search
                    , limit = model.limit
                    , offset = model.offset
                    }
            in
            Effect.fromCmd <| PostCommentsFetch.request req GotCommentsResponse

        Nothing ->
            Effect.none


searchPlaceholder : Language -> String
searchPlaceholder language =
    case language of
        English ->
            "Search"

        Ukrainian ->
            "Пошук"


commentCreateLoadingText : Language -> String
commentCreateLoadingText langauge =
    case langauge of
        English ->
            "Loading..."

        Ukrainian ->
            "Відправляємо..."
