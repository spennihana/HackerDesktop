module Widgets.Stories exposing (..)


-- sys imports
import Html exposing (Html)
import Element exposing (Element, column, text, el, empty, node, row)
import Element.Attributes exposing (px, padding, height, fill, width, fill, vary,
                                    toAttr, verticalCenter, center, spacing, id,
                                    percent, alignRight, moveDown, classList, class,
                                    alignLeft, paddingXY, attribute, yScrollbar
                                    )
import Element.Events exposing (onWithOptions, on)
import Element.Input
import Json.Decode as JDecode
import InfiniteScroll as IS
import Http
import Task
-- user imports
import Utils.Utils exposing (doTask)
import Styles exposing (Styles(..))
import Widgets.ResizeableWidget exposing (Widget, Resizer(..), Msg(..))
import Json.Decode as Decode
import Json.Decode.Extra exposing ((|:))

import Debug exposing (log)

type alias Item = {text: String}
--type alias Item
--  = { id: Int
--    , deleted: Maybe Bool
--    , type_: Maybe String
--    , by: Maybe String
--    , time: Maybe Int
--    , text: Maybe String
--    , dead: Maybe Bool
--    , parent: Maybe Int
--    , poll: Maybe Int
--    , kids: List Int
--    , url: Maybe String
--    , score: Maybe Int
--    , title: Maybe String
--    , parts: List Int
--    , descendants: Maybe Int
--    }

type StoryType = New|Top|Best|Ask|Show|Jobs

type alias Stories
  = { stories: List Item
    , type_: StoryType
    , infScroll: IS.Model Msg
    , page: Int -- pages are 30 items long
    }

type Msg
  = NoOp
  | WidgetMsg Widgets.ResizeableWidget.Msg
  | ChangeStory String
  | InfScrollMsg IS.Msg
  | OnScroll JDecode.Value
  | OnDataRetrieved (Result Http.Error (List String))
  | LoadMore

type alias StoriesWidget
  = Widgets.ResizeableWidget.Widget Stories

subscriptions: StoriesWidget -> Sub Msg
subscriptions swidg = Sub.batch [ Sub.map WidgetMsg (Widgets.ResizeableWidget.subscriptions swidg) ]

init: StoriesWidget
init =
  let infScroll = IS.init loadMore |> IS.offset 0 |> IS.direction IS.Bottom in
  Widgets.ResizeableWidget.init
    { stories=[]
    , type_=Top
    , infScroll= IS.startLoading infScroll
    , page=0
    } LeftRight .x

update: Msg -> StoriesWidget -> (StoriesWidget, Cmd Msg)
update msg widg
  = let swidget = widg.widget in
    case msg of
    NoOp -> widg ! []

    WidgetMsg wmsg ->
      let
        (newm, cmd) = Widgets.ResizeableWidget.update wmsg widg
      in
        newm ! [Cmd.map WidgetMsg cmd]

    ChangeStory story ->
      let
        stories = {stories=[], type_=str2Type story, infScroll=swidget.infScroll, page=0}
        newwidg = {widg|widget=stories}
      in
        newwidg ! [loadContent newwidg]

    InfScrollMsg imsg ->
      let (infScroll, cmd) = IS.update InfScrollMsg imsg swidget.infScroll
          newwidg = {swidget|infScroll=infScroll}
      in
        {widg| widget=newwidg} ! [cmd]

    OnDataRetrieved (Err e) ->
      let infScroll = IS.stopLoading swidget.infScroll
          newwidg = {swidget|infScroll=infScroll}
          _ = log "err" e
      in
        {widg|widget=newwidg}![]

    OnDataRetrieved (Ok result) ->
      let stories = List.concat [swidget.stories, List.map (\r -> {text=r}) result]
          infScroll = IS.stopLoading swidget.infScroll
          newwidg = {swidget|stories=stories, infScroll=infScroll, page= swidget.page+1}
      in
        {widg|widget=newwidg}![]

    OnScroll value -> widg![IS.cmdFromScrollEvent InfScrollMsg value]

    LoadMore -> widg![loadContent widg]

decoder: JDecode.Decoder (List String)
decoder = JDecode.list JDecode.string

loadContent: StoriesWidget -> Cmd Msg
loadContent s
  = let url = "http://localhost:3984/" ++ (type2Str s) ++ "/" ++ (toString s.widget.page) in
    Http.get url decoder
      |> Http.send OnDataRetrieved

loadMore : IS.Direction -> Cmd Msg
loadMore dir
  = doTask LoadMore

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
  = column None
      [ width <| px <| toFloat swidg.dinfo.h0
      , height fill
      ][ header swidg
       , items swidg
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

items: StoriesWidget -> Element Styles v Msg
items swidg
  = column Items
      [ height fill
      , width fill
      , yScrollbar
      , on "scroll" (JDecode.map OnScroll JDecode.value)
      ]
      [ column None [height <| px 40, width fill]
          <| List.map (\s -> storyItem s) swidg.widget.stories
      ]

storyItem: Item -> Element Styles v Msg
storyItem item
  = el None[](text item.text)

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