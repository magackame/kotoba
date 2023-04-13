module Shared.View.Post.CommentCreateError exposing (CommentCreateError(..), translate)

import Language exposing (Language(..))


type CommentCreateError
    = ContentIsRequired
    | ServerError


translate : Language -> CommentCreateError -> String
translate language error =
    case error of
        ContentIsRequired ->
            case language of
                English ->
                    "Enter content"

                Ukrainian ->
                    "Введіть зміст"

        ServerError ->
            case language of
                English ->
                    "Server error"

                Ukrainian ->
                    "Помилка на сервері"
