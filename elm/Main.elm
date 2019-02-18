module Main exposing (Model, Msg(..), TodoItem, init, initialModel, main, subscriptions, todoItemEdit, todoItemRow, update, view)

import Browser
import Html exposing (Html, button, div, form, input, span, text)
import Html.Attributes exposing (id, placeholder, required, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode exposing (Decoder, field, int, list, map2, string)
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
    { id : Int
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
    | DeleteItem Int
    | DeleteItemResult (Result Http.Error String)


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
                    ( { model | error = Just "Decoding error" }, Cmd.none )

                Ok i ->
                    ( { model | items = i }, Cmd.none )

        EditNewItem i ->
            ( { model | newItem = i }, Cmd.none )

        PostNewItem ->
            ( { model | newItem = "" }, postNewItem model.newItem )

        PostNewItemResult res ->
            case res of
                Err _ ->
                    ( { model | error = Just "HTTP error" }, Cmd.none )

                Ok _ ->
                    ( model, loadData )

        DeleteItem id ->
            ( model, deleteItem id )

        DeleteItemResult res ->
            case res of
                Err _ ->
                    ( { model | error = Just "HTTP error" }, Cmd.none )

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
            ++ [ form [ onSubmit PostNewItem ]
                    [ input [ type_ "text", required True, placeholder "Add a todo", onInput EditNewItem ] []
                    , button [ onClick PostNewItem ] [ text "Add" ]
                    ]
               ]
        )


todoItemRow : TodoItem -> Html Msg
todoItemRow i =
    div []
        [ todoItemEdit i
        , button [ onClick (DeleteItem i.id) ] [ text "X" ]
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
        { url = "/api/todo?order=date_added.asc"
        , expect = Http.expectJson DecodeItems todoListDecoder
        }


deleteItem : Int -> Cmd Msg
deleteItem id =
    delete
        { url = "/api/todo?todo_id=eq." ++ (String.fromInt id)
        , expect = Http.expectString DeleteItemResult
        }


postNewItem : String -> Cmd Msg
postNewItem s =
    if not (String.isEmpty s) then
        Http.post
            { url = "/api/todo"
            , expect = Http.expectString PostNewItemResult
            , body = Http.stringBody "application/json" (todoItemEncoder s)
            }
    else
        Cmd.none


todoListDecoder : Decoder (List TodoItem)
todoListDecoder =
    list
        (map2 (\id body -> { id = id, body = body, edit = False })
            (field "todo_id" int)
            (field "body" string)
        )


todoItemEncoder : String -> String
todoItemEncoder s =
    Encode.encode 0 (Encode.list Encode.object [ [ ( "body", Encode.string s ) ] ])

delete
  : { url : String
    , expect : Http.Expect msg
    }
  -> Cmd msg
delete r =
  Http.request
    { method = "DELETE"
    , headers = []
    , url = r.url
    , body = Http.emptyBody
    , expect = r.expect
    , timeout = Nothing
    , tracker = Nothing
    }
