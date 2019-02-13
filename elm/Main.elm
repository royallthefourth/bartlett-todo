module Main exposing (Model, Msg(..), TodoItem, init, initialModel, main, subscriptions, todoItemEdit, todoItemRow, update, view)

import Browser
import Html exposing (Html, button, div, input, span, text)
import Html.Attributes exposing (id, required, type_, value)
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
    = EditClicked TodoItem


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EditClicked item ->
            let
                e =
                    List.map
                        (\el ->
                            if el.id == item.id then
                                { id = item.id
                                , body = item.body
                                , edit = True
                                }

                            else
                                el
                        )
                        model.items
            in
            ( { model | items = e }, Cmd.none )


view : Model -> Html Msg
view model =
    div [ id "elm" ]
        ([ span []
            [ text
                (case model.error of
                    Just e ->
                        e

                    Nothing ->
                        ""
                )
            ]
         ]
            ++ List.map todoItemRow model.items
            ++ [ input [ type_ "text", required True ] [] -- TODO add new item onblur
               ]
        )


todoItemRow : TodoItem -> Html Msg
todoItemRow i =
    div []
        [ todoItemEdit i
        , button [] [ text "X" ] -- TODO add click event for delete
        ]


todoItemEdit : TodoItem -> Html Msg
todoItemEdit i =
    if i.edit == True then
        input [ type_ "text", required True, value i.body ] []
        -- TODO add edit field with update onblur

    else
        span [ onClick (EditClicked i) ] [ text i.body ]
