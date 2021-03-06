module Main exposing (main)

import Html.App as App
import Html exposing (div, h1, text, form, input, button, table, tr, td, p, a)
import Html.Attributes exposing (class, type', placeholder, value, href)
import Html.Events exposing (onClick, onInput, onSubmit)
import WebSocket
import Json.Decode exposing (Decoder, decodeString, list, string)
import String


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
            if String.isEmpty (String.trim model.message) then
                ( model, Cmd.none )
            else
                ( { model | message = "" }
                , WebSocket.send (websocketUrl model) model.message
                )

        MessageRecieved payload ->
            let
                recievedMessages =
                    decodeString messagesDecoder payload
                        |> Result.withDefault []

                messages =
                    case model.messages of
                        Nothing ->
                            recievedMessages

                        Just msgs ->
                            List.append msgs recievedMessages
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
    div []
        [ p [] [ text "This is a chat app written in Kemal and Elm." ]
        , p []
            [ text "The source code is available "
            , a [ href "https://github.com/kofno/kemal_elm_chat" ]
                [ text "here" ]
            , text "."
            ]
        ]


callToAction : Html.Html Msg
callToAction =
    div []
        [ p [] [ text "Try it out!" ] ]


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


messagesDecoder : Decoder (List String)
messagesDecoder =
    list string
