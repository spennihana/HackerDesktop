module Widgets.Stories exposing (..)


-- sys imports
import Html exposing (Html)
import Element exposing (Element, column, text, el, empty, node, row, wrappedRow, wrappedColumn, newTab,
                         paragraph, textLayout, full, html)
import Element.Attributes exposing (px, padding, height, fill, width, fill, vary,
                                    toAttr, verticalCenter, center, spacing, id,
                                    percent, alignRight, alignBottom, moveDown, classList, class,
                                    alignLeft, paddingXY, attribute, yScrollbar, xScrollbar, moveLeft
                                    )
import Element.Events exposing (onWithOptions, on, onClick)
import Element.Input
import Json.Decode as JDecode
import InfiniteScroll as IS
import Http
import Html
import Html.Attributes
import Task
import Time exposing (Time)
-- user imports
import Utils.Utils exposing (doTask, humanTime, urlScrape)
import Utils.Decoders exposing (Item, decodeItem)
import Styles exposing (Styles(..))
import Widgets.ResizeableWidget exposing (Widget, Resizer(..), Msg(..))
import Json.Decode as Decode
import Json.Decode.Extra exposing ((|:))

import Debug exposing (log)


type StoryType = New|Top|Best|Ask|Show|Jobs

type alias Stories
  = { stories: List Item
    , type_: StoryType
    , infScroll: IS.Model Msg
    , page: Int -- pages are 30 items long
    , curtime: Int
    }

type Msg
  = NoOp
  | WidgetMsg Widgets.ResizeableWidget.Msg
  | ChangeStory String
  | InfScrollMsg IS.Msg
  | OnScroll JDecode.Value
  | OnDataRetrieved (Result Http.Error (List Item))
  | Reset (Result Http.Error Bool)
  | OnTime Time
  | LoadMore
  | ShowComments Item

type alias StoriesWidget
  = Widgets.ResizeableWidget.Widget Stories

subscriptions: StoriesWidget -> Sub Msg
subscriptions swidg = Sub.batch [ Sub.map WidgetMsg (Widgets.ResizeableWidget.subscriptions swidg) ]

init: StoriesWidget
init =
  let infScroll = IS.init loadMore |> IS.offset 800 |> IS.direction IS.Bottom in
  Widgets.ResizeableWidget.init
    { stories=[]
    , type_=Top
    , infScroll= IS.startLoading infScroll
    , page=0
    , curtime=0
    } LeftRight .x

update: Msg -> StoriesWidget -> (StoriesWidget, Cmd Msg)
update msg widg
  = let swidget = widg.widget in
    case msg of
    NoOp ->
      widg![]

    WidgetMsg wmsg ->
      let
        (newm, cmd) = Widgets.ResizeableWidget.update wmsg widg
      in
        newm ! [Cmd.map WidgetMsg cmd]

    ChangeStory story ->
      let
        stories = {stories=[], type_=str2Type story, infScroll=swidget.infScroll, page=0,curtime=0}
        newwidg = {widg|widget=stories}
      in
        newwidg ! [resetContent widg, loadContent newwidg]

    InfScrollMsg imsg ->
      let (infScroll, cmd) = IS.update InfScrollMsg imsg swidget.infScroll
          newwidg = {swidget|infScroll=infScroll}
      in
        {widg| widget=newwidg} ! [cmd]

    Reset r ->
      widg![]

    OnDataRetrieved (Err e) ->
      let infScroll = IS.stopLoading swidget.infScroll
          newwidg = {swidget|infScroll=infScroll}
          _ = log "err" e
      in
        {widg|widget=newwidg}![]

    OnDataRetrieved (Ok result) ->
      let stories = List.concat [swidget.stories, result]
          infScroll = IS.stopLoading swidget.infScroll
          newwidg = {swidget|stories=stories, infScroll=infScroll, page= swidget.page+1}
      in
        {widg|widget=newwidg}![Task.perform OnTime Time.now]

    OnScroll value ->
      widg![IS.cmdFromScrollEvent InfScrollMsg value]

    LoadMore ->
      widg![loadContent widg]

    ShowComments item ->
      widg![]  -- show logic handled in main updater

    OnTime t ->
      let newwidg = {swidget|curtime=round <| t/1000} in
      {widg| widget=newwidg} ! []

decoder: JDecode.Decoder (List Item)
decoder = JDecode.list decodeItem

resetContent: StoriesWidget -> Cmd Msg
resetContent s
  = let url = "http://localhost:3984/reset" in
    Http.get url (JDecode.succeed True)
      |> Http.send Reset

loadContent: StoriesWidget -> Cmd Msg
loadContent s
  = let url = "http://localhost:3984/stories/" ++ (String.toLower <| type2Str s) ++ "/" ++ (toString <| nToFetch s) in
    Http.get url decoder
      |> Http.send OnDataRetrieved

loadMore : IS.Direction -> Cmd Msg
loadMore dir
  = doTask LoadMore

-- could do something more thoughtful here later...
nToFetch: StoriesWidget -> Int
nToFetch s
  = case s.widget.page>0 of
    True -> 5
    False -> 20

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
      , paddingXY 10 0
      , yScrollbar
      , on "scroll" (JDecode.map OnScroll JDecode.value)
      ]
      [ column None [height <| px 40, width fill]
          <| (List.filter (\s -> not s.deleted) swidg.widget.stories
              |> List.map (\s -> storyItem s swidg.widget.curtime) )
      ]

storyItem: Item -> Int -> Element Styles v Msg
storyItem item curtime
  = column StoryItem
      [ height <| px 80
      , width fill
      , spacing 8
      ][ row StoryItemHeader[][text item.by, text " | ", text <| humanTime (toFloat<| curtime - item.time)]
       , row StoryItemTitle[height <| px 20, xScrollbar]
          [newTab item.url
            <| html
            <| Html.div[Html.Attributes.style[("width", "100%"), ("white-space", "nowrap"), ("overflow-y", "hidden"), ("overflow-x", "scroll")]] -- FIXME: hack to get horizontal text scroll
                       [Html.text item.title]]
       , row None[height <| px 30]
          [ column None[alignBottom, width <| percent 80][row StoryItemHeader[][text <| (toString item.score) ++ " | " ++ urlScrape item.url]]
          , column None[width fill, height fill]
              [row None[alignRight, moveLeft 10, onWithOptions "click" Utils.Utils.clickOptionsTF (JDecode.succeed NoOp)]
                  [ row CommentBubbleWrapper[onClick (ShowComments item)]
                    [ el CommentBubble
                      [height <| px 30, width <| px 30
                      ](node "i" <| el None [class "fa fa-comments", center, verticalCenter] empty)
                    , el None[verticalCenter](text <| String.padLeft 2 ' ' <| toString <| List.length item.kids)
                    ]
                  ]
              ]
          ]
       ]

dragger: StoriesWidget -> Element Styles v Widgets.ResizeableWidget.Msg
dragger swidg
  = column Dragger
    [height fill
    , width <| px 2
    , onWithOptions "mousedown" Utils.Utils.clickOptionsTT (JDecode.succeed DragStart)
    ][el DraggerInner [height fill, width <| px 1, center](empty)]
