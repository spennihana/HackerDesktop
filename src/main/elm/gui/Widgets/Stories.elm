module Widgets.Stories exposing (..)


-- sys imports
import Html exposing (Html)
import Element exposing (Element, column, text, el, empty, node, row)
import Element.Attributes exposing (px, padding, height, fill, width, fill, vary,
                                    toAttr, verticalCenter, center, spacing, id,
                                    percent, alignRight, moveDown, classList, class,
                                    alignLeft, paddingXY, attribute
                                    )
import Element.Events exposing (onWithOptions)
import Element.Input
import Json.Decode as JDecode
import Utils.Utils

-- user imports
import Styles exposing (Styles(..))
import Widgets.ResizeableWidget exposing (Widget, Resizer(..), Msg(..))

import Debug exposing (log)


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

type StoryType = New|Top|Best|Ask|Show|Jobs

type alias Stories
  = { stories: List Item
    , type_: StoryType
    }

type Msg
  = NoOp
  | WidgetMsg Widgets.ResizeableWidget.Msg
  | ChangeStory String

type alias StoriesWidget
  = Widgets.ResizeableWidget.Widget Stories

subscriptions: StoriesWidget -> Sub Msg
subscriptions swidg = Sub.batch [ Sub.map WidgetMsg (Widgets.ResizeableWidget.subscriptions swidg) ]

init: StoriesWidget
init =
  Widgets.ResizeableWidget.init {stories=[], type_=Top} LeftRight .x

update: Msg -> StoriesWidget -> (StoriesWidget, Cmd Msg)
update msg widg
  = case msg of
    NoOp -> widg ! []
    WidgetMsg wmsg ->
      let
        (newm, cmd) = Widgets.ResizeableWidget.update wmsg widg
      in
        newm ! [Cmd.map WidgetMsg cmd]
    ChangeStory story ->
      let
        stories = {stories=[], type_=str2Type story}
      in
        {widg|widget=stories} ! []

str2Type: String -> StoryType
str2Type s
  = case s of
    "New" -> New
    "Top" -> Top
    "Best" -> Best
    "Ask" -> Ask
    "Show" -> Show
    "Jobs" -> Jobs
    _ -> Debug.crash "shouldn't happen"

type2Str: StoriesWidget -> String
type2Str swidg
  = case swidg.widget.type_ of
    New -> "New"
    Top -> "Top"
    Best -> "Best"
    Ask -> "Ask"
    Show -> "Show"
    Jobs -> "Jobs"

view: StoriesWidget -> Element Styles v Msg
view swidg
  = row None[width <| px <| toFloat swidg.dinfo.h0, height fill]
      [stories swidg, Element.map WidgetMsg <| dragger swidg]

stories: StoriesWidget -> Element Styles v Msg
stories swidg
  = row None
      [ width fill
      , height fill
      ][ header swidg
       , empty
       ]

header: StoriesWidget -> Element Styles v Msg
header swidg
  = row StoriesHeader
      [ width fill
      , height <| px 100
      , padding 20
      ]
      [ el None[verticalCenter](text <| type2Str swidg)
      , row None
         [height fill, width fill, alignRight, verticalCenter]
         [el Refresh
            [height <| px 30, width <| px 30
            ](node "i" <| el None [class "fa fa-refresh", center, verticalCenter] empty)]]

dragger: StoriesWidget -> Element Styles v Widgets.ResizeableWidget.Msg
dragger swidg
  = column Dragger
    [height fill
    , width <| px 2
    , onWithOptions "mousedown" Utils.Utils.clickOptionsTT (JDecode.succeed DragStart)
    ][el DraggerInner [height fill, width <| px 1, center](empty)]

footer: StoriesWidget -> Element Styles v Msg
footer swidg
  = el None[](empty)