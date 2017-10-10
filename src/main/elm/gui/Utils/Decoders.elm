module Utils.Decoders exposing (..)

import Json.Decode as JDecode exposing (field)
import Json.Decode.Pipeline exposing (decode, required, optional)

import Element exposing (el, empty, Element)
import Styles exposing (..)

type alias Item
  = { id: Int
    , deleted: Maybe Bool
    , type_: Maybe String
    , by: Maybe String
    , time: Maybe Int
    , text: Maybe String
    , dead: Maybe Bool
    , parent: Maybe Int
    , poll: Maybe Int
    , kids: List Int
    , url: Maybe String
    , score: Maybe Int
    , title: Maybe String
    , parts: List Int
    , descendants: Maybe Int
    }

decodeItem: JDecode.Decoder Item
decodeItem
  = decode Item
    |> required "id" JDecode.int
    |> optional "deleted" (JDecode.map Just JDecode.bool) Nothing
    |> optional "type" (JDecode.map Just JDecode.string) Nothing
    |> optional "by" (JDecode.map Just JDecode.string) Nothing
    |> optional "time" (JDecode.map Just JDecode.int) Nothing
    |> optional "text" (JDecode.map Just JDecode.string) Nothing
    |> optional "dead" (JDecode.map Just JDecode.bool) Nothing
    |> optional "parent" (JDecode.map Just JDecode.int) Nothing
    |> optional "poll" (JDecode.map Just JDecode.int) Nothing
    |> optional "kids" (JDecode.list JDecode.int) []
    |> optional "url" (JDecode.map Just JDecode.string) Nothing
    |> optional "score" (JDecode.map Just JDecode.int) Nothing
    |> optional "title" (JDecode.map Just JDecode.string) Nothing
    |> optional "parts" (JDecode.list JDecode.int) []
    |> optional "descendants" (JDecode.map Just JDecode.int) Nothing

viewItem: msg -> Item -> Element Styles v msg
viewItem msg item
  = el None[](empty)