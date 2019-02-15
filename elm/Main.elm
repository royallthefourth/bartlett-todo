module Main exposing (Model, Msg(..), TodoItem, init, initialModel, main, subscriptions, todoItemEdit, todoItemRow, update, view)

import Browser
import Html exposing (Html, button, div, input, span, text)
import Html.Attributes exposing (id, placeholder, required, type_, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, list, map2, string)
import Json.Encode as Encode


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


type alias Model =
    { error : Maybe String
    , items : List TodoItem
    , newItem : String
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
    , newItem = ""
    }


type Msg
    = EnableEdit TodoItem
    | FetchItems
    | DecodeItems (Result Http.Error (List TodoItem))
    | EditNewItem String
    | PostNewItem
    | PostNewItemResult (Result Http.Error String)


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
            case res of
                Err _ ->
                    ( { model | error = Just "There was an error" }, Cmd.none )

                Ok i ->
                    ( { model | items = i }, Cmd.none )

        EditNewItem i ->
            ( { model | newItem = i }, Cmd.none )

        PostNewItem ->
            ( { model | newItem = "" }, postNewItem model.newItem )

        PostNewItemResult res ->
            case res of
                Err _ ->
                    ( { model | error = Just "There was an error" }, Cmd.none )

                Ok _ ->
                    ( model, loadData )


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
            ++ [ input [ type_ "text", required True, placeholder "Add a todo", onInput EditNewItem, onBlur PostNewItem ] []
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
        -- TODO add update onblur
    else
        span [ onClick (EnableEdit i) ] [ text i.body ]


loadData : Cmd Msg
loadData =
    Http.get
        { url = "/api/todo"
        , expect = Http.expectJson DecodeItems (list todoItemDecoder)
        }

postNewItem : String -> Cmd Msg
postNewItem s =
    Http.post
        { url = "/api/todo"
        , expect = Http.expectString PostNewItemResult
        , body = Http.stringBody "application/json" (todoItemEncoder s)
        }


todoItemDecoder : Decoder TodoItem
todoItemDecoder =
    map2 (\id body -> { id = id, body = body, edit = False })
        (field "todo_id" string)
        (field "body" string)


todoItemEncoder : String -> String
todoItemEncoder s =
    Encode.encode 0 (Encode.list Encode.object [ [ ( "body", Encode.string s ) ] ])