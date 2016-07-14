module Main exposing (main)

import Html.App as App
import Html exposing (div, h1, text, form, input, button, table, tr, td)
import Html.Attributes exposing (class, type', placeholder, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import WebSocket


type alias Config =
    { locationHost : String
    , protocol : String
    }


type alias Model =
    { messages : Maybe (List String)
    , message : String
    , config : Config
    }


type Msg
    = Reset
    | Change String
    | SendMessage
    | MessageRecieved String


main : Program Config
main =
    App.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


websocketProtocol : Model -> String
websocketProtocol model =
    case model.config.protocol of
        "https:" ->
            "wss:"

        _ ->
            "ws:"


websocketUrl : Model -> String
websocketUrl model =
    websocketProtocol model ++ "//" ++ model.config.locationHost ++ "/chat"


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen (websocketUrl model) MessageRecieved


initialModel : Config -> Model
initialModel flags =
    { messages = Nothing
    , message = ""
    , config = flags
    }


init : Config -> ( Model, Cmd Msg )
init flags =
    ( initialModel flags, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Reset ->
            ( { model | messages = Nothing }, Cmd.none )

        Change newMessage ->
            ( { model | message = newMessage }, Cmd.none )

        SendMessage ->
            ( { model | message = "" }
            , WebSocket.send (websocketUrl model) model.message
            )

        MessageRecieved message ->
            let
                messages =
                    case model.messages of
                        Nothing ->
                            [ message ]

                        Just msgs ->
                            List.append msgs [ message ]
            in
                ( { model | messages = Just messages }, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div [ class "container" ]
        [ jumboTron model
        , resetButton
        , messageList model
        ]


jumboTron : Model -> Html.Html Msg
jumboTron model =
    div [ class "jumbotron" ]
        [ greeting
        , description
        , callToAction
        , messageForm model
        ]


greeting : Html.Html Msg
greeting =
    h1 [] [ text "'Allo!" ]


description : Html.Html Msg
description =
    div [] [ text "This is a chat app written in Kemal and Elm" ]


callToAction : Html.Html Msg
callToAction =
    div [] [ text "Try it out!" ]


messageForm : Model -> Html.Html Msg
messageForm model =
    form [ class "form-inline", onSubmit SendMessage ]
        [ input
            [ type' "text"
            , class "form-control"
            , placeholder "Write a Message!"
            , onInput Change
            , value model.message
            ]
            []
        , button [ class "btn btn-default" ] [ text "Send!" ]
        ]


messageList : Model -> Html.Html Msg
messageList model =
    case model.messages of
        Nothing ->
            div [] [ text "You haven't received any messages yet!" ]

        Just msgs ->
            table [ class "table table-condensed" ]
                (List.map messageRow msgs)


messageRow : String -> Html.Html Msg
messageRow msg =
    tr []
        [ td [] [ text msg ] ]


resetButton : Html.Html Msg
resetButton =
    button [ class "btn btn-danger", onClick Reset ]
        [ text "Clear Messages" ]
