module Ago exposing (format)

import Language exposing (Language(..))


type Ago
    = Years
    | Months
    | Weeks
    | Days
    | Hours
    | Minutes
    | Seconds


format : Language -> Int -> String
format language seconds =
    let
        ( ago, n ) =
            calculate seconds [ ( Years, years ), ( Months, months ), ( Weeks, weeks ), ( Days, days ), ( Hours, hours ), ( Minutes, minutes ) ]

        number =
            String.fromInt n

        time =
            toString language ( ago, n )

        suffix =
            case language of
                English ->
                    "ago"

                Ukrainian ->
                    "тому"
    in
    number ++ " " ++ time ++ " " ++ suffix


calculate : Int -> List ( Ago, Int -> Int ) -> ( Ago, Int )
calculate seconds functions =
    case functions of
        ( ago, f ) :: fns ->
            let
                n =
                    f seconds
            in
            if n /= 0 then
                ( ago, n )

            else
                calculate seconds fns

        _ ->
            ( Seconds, seconds )


toString : Language -> ( Ago, Int ) -> String
toString language ( ago, n ) =
    let
        lastDigit =
            remainderBy 10 n
    in
    case ago of
        Years ->
            case language of
                English ->
                    if n == 1 then
                        "year"

                    else
                        "years"

                Ukrainian ->
                    if n >= 10 && n <= 20 then
                        "років"

                    else
                        case lastDigit of
                            1 ->
                                "рік"

                            2 ->
                                "роки"

                            3 ->
                                "роки"

                            4 ->
                                "роки"

                            _ ->
                                "років"

        Months ->
            case language of
                English ->
                    if n == 1 then
                        "month"

                    else
                        "months"

                Ukrainian ->
                    if n >= 10 && n <= 20 then
                        "місяців"

                    else
                        case lastDigit of
                            1 ->
                                "місяць"

                            2 ->
                                "місяці"

                            3 ->
                                "місяці"

                            4 ->
                                "місяці"

                            _ ->
                                "місяців"

        Weeks ->
            case language of
                English ->
                    if n == 1 then
                        "week"

                    else
                        "weeks"

                Ukrainian ->
                    if n >= 10 && n <= 20 then
                        "тижнів"

                    else
                        case lastDigit of
                            1 ->
                                "тиждень"

                            2 ->
                                "тижні"

                            3 ->
                                "тижні"

                            4 ->
                                "тижні"

                            _ ->
                                "тижнів"

        Days ->
            case language of
                English ->
                    if n == 1 then
                        "day"

                    else
                        "days"

                Ukrainian ->
                    if n >= 10 && n <= 20 then
                        "днів"

                    else
                        case lastDigit of
                            1 ->
                                "день"

                            2 ->
                                "дні"

                            3 ->
                                "дні"

                            4 ->
                                "дні"

                            _ ->
                                "днів"

        Hours ->
            case language of
                English ->
                    if n == 1 then
                        "hour"

                    else
                        "hours"

                Ukrainian ->
                    if n >= 10 && n <= 20 then
                        "годин"

                    else
                        case lastDigit of
                            1 ->
                                "годину"

                            2 ->
                                "години"

                            3 ->
                                "години"

                            4 ->
                                "години"

                            _ ->
                                "годин"

        Minutes ->
            case language of
                English ->
                    if n == 1 then
                        "minute"

                    else
                        "minutes"

                Ukrainian ->
                    if n >= 10 && n <= 20 then
                        "хвилин"

                    else
                        case lastDigit of
                            1 ->
                                "хвилину"

                            2 ->
                                "хвилини"

                            3 ->
                                "хвилини"

                            4 ->
                                "хвилини"

                            _ ->
                                "хвилин"

        Seconds ->
            case language of
                English ->
                    if n == 1 then
                        "second"

                    else
                        "seconds"

                Ukrainian ->
                    if n >= 10 && n <= 20 then
                        "секунд"

                    else
                        case lastDigit of
                            1 ->
                                "секунду"

                            2 ->
                                "секунди"

                            3 ->
                                "секунди"

                            4 ->
                                "секунди"

                            _ ->
                                "секунд"


secondsInAMinute : Int
secondsInAMinute =
    60


secondsInAnHour : Int
secondsInAnHour =
    60 * secondsInAMinute


secondsInADay : Int
secondsInADay =
    24 * secondsInAnHour


years : Int -> Int
years seconds =
    seconds // 365 // secondsInADay


months : Int -> Int
months seconds =
    seconds // 30 // secondsInADay


weeks : Int -> Int
weeks seconds =
    seconds // 7 // secondsInADay


days : Int -> Int
days seconds =
    seconds // secondsInADay


hours : Int -> Int
hours seconds =
    seconds // secondsInAnHour


minutes : Int -> Int
minutes seconds =
    seconds // secondsInAMinute
