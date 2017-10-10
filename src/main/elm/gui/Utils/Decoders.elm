module Utils.Decoders exposing (..)

import Json.Decode as JDecode exposing (field)
import Json.Decode.Pipeline exposing (decode, required, optional)

import Element exposing (el, empty, Element, column, row)
import Element.Attributes exposing (width, height, fill, px)
import Styles exposing (..)

type alias Item
  = { id: Int
    , deleted: Bool
    , type_: String
    , by: String
    , time: Int
    , text: String
    , dead: Bool
    , parent: Int
    , poll: Int
    , kids: List Int
    , url: String
    , score: Int
    , title: String
    , parts: List Int
    , descendants: Int
    }

decodeItem: JDecode.Decoder Item
decodeItem
  = decode Item
    |> required "id" JDecode.int
    |> optional "deleted" JDecode.bool False
    |> optional "type" JDecode.string ""
    |> optional "by" JDecode.string ""
    |> optional "time" JDecode.int -1
    |> optional "text" JDecode.string ""
    |> optional "dead" JDecode.bool False
    |> optional "parent" JDecode.int -1
    |> optional "poll" JDecode.int -1
    |> optional "kids" (JDecode.list JDecode.int) []
    |> optional "url" JDecode.string ""
    |> optional "score" JDecode.int -1
    |> optional "title" JDecode.string ""
    |> optional "parts" (JDecode.list JDecode.int) []
    |> optional "descendants" JDecode.int -1