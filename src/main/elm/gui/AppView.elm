module AppView exposing (view)
-- sys imports
import Element exposing (column, text, Element, row, el, empty, node)
import Element.Attributes exposing (px, padding, height, fill, width, fill, alignRight, class, paddingXY, paddingTop,
                                    vary, verticalCenter, center, spacing, id, percent, inlineStyle, yScrollbar)
import Element.Events exposing (onWithOptions, onClick)
import Html exposing (Html)
import Json.Decode as JDecode
-- user imports
import Styles exposing (Styles(..), SidebarButtonStyles(..), appstyles)
import Utils.Utils exposing (clickOptionsTT)
import Utils.Constants exposing (..)
import HNDTypes exposing (HNDMsg(..), HNDView(..))
import AppModel exposing (HNDModel)
import Widgets.Stories exposing (Msg(..))
import Widgets.Comments

import Debug exposing (log)

view: HNDModel -> Html HNDMsg
view model
  = Element.viewport appstyles <|
      el Root
        [height fill, width fill]
        (app model)

header: Element Styles v HNDMsg
header
  = column Header [width fill, height <| px 25] [Element.empty]

app: HNDModel -> Element Styles v HNDMsg
app model
  = row None
      [width fill, height fill]
      [sidebar model, stories model, comments model]

sidebar: HNDModel -> Element Styles v HNDMsg
sidebar model
  = column Sidebar
    [ width <| px sidebarwidth
    , height fill
    , padding 5
    , center
    , spacing 20
    ]
    <| [header] ++ (sidebtns model)

sidebtns: HNDModel -> List (Element Styles v HNDMsg)
sidebtns model
  = List.map (\n -> sidebtn model n) [ "New", "Top", "Best", "Ask", "Show", "Jobs"]

sidebtn: HNDModel -> String -> Element Styles v HNDMsg
sidebtn model name
  = let btnStyle = case (Widgets.Stories.type2Str model.storyWidget) == name of
                   True -> SidebarButton Selected
                   False -> SidebarButton Normal
    in
    Element.map StoriesMsg <|
    column btnStyle
      [ width <| px 50
      , height <| px 50
      , class "waves-light"
      , verticalCenter
      , center
      , onWithOptions "click" clickOptionsTT (JDecode.succeed (ChangeStory name))
      ] [text name]

stories: HNDModel -> Element Styles v HNDMsg
stories model
  = Element.map StoriesMsg (Widgets.Stories.view model.storyWidget)

comments: HNDModel -> Element Styles v HNDMsg
comments model
  = Element.map CommentsMsg (Widgets.Comments.view model.commentsWidget)