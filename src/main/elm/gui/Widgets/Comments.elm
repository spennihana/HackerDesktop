module Widgets.Comments exposing (..)


-- sys imports
import Html exposing (Html)
import Element exposing (Element, column, text, el, empty, node, row)
import Element.Attributes exposing (px, padding, height, fill, width, fill, vary,
                                    toAttr, verticalCenter, center, spacing, id,
                                    percent, alignRight, moveRight, classList, class,
                                    alignLeft, paddingXY, attribute
                                    )
import Element.Events exposing (onWithOptions)
import Element.Input
import Json.Decode as JDecode
import Utils.Utils

-- user imports
import Styles exposing (Styles(..))

import Debug exposing (log)


type alias Comment
  = { id: Int
    , text: String
    , children: Responses
    }

type Responses = Responses (List Comment)

type Msg
  = NoOp

type alias CommentsWidget = List Comment

init: CommentsWidget
init = []

update: Msg -> CommentsWidget -> (CommentsWidget, Cmd Msg)
update msg widg
  = case msg of
    NoOp -> widg ! []

view: CommentsWidget -> Element Styles v Msg
view cwidg
  = row None[moveRight 2, width fill, height fill]
      [comments cwidg]

comments: CommentsWidget -> Element Styles v Msg
comments cwidg
  = row None[width fill, height fill][header cwidg, empty]

header: CommentsWidget -> Element Styles v Msg
header swidg
  = row Header [width fill, height <| px 25] [Element.empty]