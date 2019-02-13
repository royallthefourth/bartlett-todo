module Main exposing (Model, Msg(..), TodoItem, init, initialModel, main, subscriptions, todoItemEdit, todoItemRow, update, view)

import Browser
import Html exposing (Html, button, div, input, span, text)
import Html.Attributes exposing (id, placeholder, required, type_, value)
import Html.Events exposing (onBlur, onClick)
import Http
import Json.Decode exposing (Decoder, field, list, map2, string)


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
    ( initialModel, loadData )



-- TODO query for items on load


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
    = EnableEdit TodoItem
    | FetchItems
    | DecodeItems (Result Http.Error (List TodoItem))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EnableEdit item ->
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

        FetchItems ->
            ( model, loadData )

        DecodeItems res ->
            -- TODO handle decoder results
            ( model, Cmd.none )


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
            ++ [ input [ type_ "text", required True, placeholder "Add a todo" ] [] -- TODO add new item onblur
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
        span [ onClick (EnableEdit i) ] [ text i.body ]


loadData : Cmd Msg
loadData =
    Http.get
        { url = "/api/todo"
        , expect = Http.expectJson DecodeItems (list todoItemDecoder)
        }


todoItemDecoder : Decoder TodoItem
todoItemDecoder =
    map2 (\id body -> { id = id, body = body, edit = False })
        (field "todo_id" string)
        (field "body" string)
