module Language exposing (Language(..), default, emailInputPlaceholder, passwordInputPlaceholder, translateMonth)

import Time exposing (Month(..))


type Language
    = English
    | Ukrainian


default : Language
default =
    Ukrainian


emailInputPlaceholder : Language -> String
emailInputPlaceholder language =
    case language of
        English ->
            "Email"

        Ukrainian ->
            "Електронна пошта"


passwordInputPlaceholder : Language -> String
passwordInputPlaceholder language =
    case language of
        English ->
            "Password"

        Ukrainian ->
            "Пароль"


translateMonth : Language -> Month -> String
translateMonth language month =
    case month of
        Jan ->
            case language of
                English ->
                    "January"

                Ukrainian ->
                    "Січень"

        Feb ->
            case language of
                English ->
                    "Febuary"

                Ukrainian ->
                    "Лютий"

        Mar ->
            case language of
                English ->
                    "March"

                Ukrainian ->
                    "Березень"

        Apr ->
            case language of
                English ->
                    "April"

                Ukrainian ->
                    "Квітень"

        May ->
            case language of
                English ->
                    "May"

                Ukrainian ->
                    "Травень"

        Jun ->
            case language of
                English ->
                    "June"

                Ukrainian ->
                    "Червень"

        Jul ->
            case language of
                English ->
                    "July"

                Ukrainian ->
                    "Липень"

        Aug ->
            case language of
                English ->
                    "August"

                Ukrainian ->
                    "Серпень"

        Sep ->
            case language of
                English ->
                    "September"

                Ukrainian ->
                    "Вересень"

        Oct ->
            case language of
                English ->
                    "October"

                Ukrainian ->
                    "Жовтень"

        Nov ->
            case language of
                English ->
                    "November"

                Ukrainian ->
                    "Листопад"

        Dec ->
            case language of
                English ->
                    "December"

                Ukrainian ->
                    "Грудень"
