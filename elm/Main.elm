module Main exposing (..)

import Browser
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (id)
import Html.Events exposing (onBlur, onClick)


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )


type alias Model =
    { error : Maybe String
    , items : List TodoItem
    }


type alias TodoItem =
    { id : String
    , body : String
    , edit : Bool
    }


initialModel : Model
initialModel =
    { error = Nothing
    , items = []
    }


type Msg
    = Increment
    | Decrement


update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1


view : Model -> Cmd Msg
view model =
    div [ id "elm" ]
        [ span [] [text
            case model.error of
            Just String -> model.error
            Nothing -> Just ""
        ]
        , List.map todoItemRow model.items
        , button [ onClick Increment ] [ text "+" ] -- TODO add entry field
        ]


todoItemRow : TodoItem -> Cmd Msg
todoItemRow i =
    div []
        [ todoItemEdit i
        , button [] [ text "X" ] -- TODO add click event for delete
        ]


todoItemEdit : TodoItem -> Cmd Msg
todoItemEdit i =
    if i.edit == True then
        text i.body
        -- TODO add edit field with update onblur
    else
        text i.body
