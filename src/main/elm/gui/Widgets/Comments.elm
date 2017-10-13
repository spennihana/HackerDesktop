module Widgets.Comments exposing (..)


-- sys imports
import Dict exposing (Dict)
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
import Time exposing (Time)
import Task
import Http

-- user imports
import Styles exposing (Styles(..))
import Utils.Decoders exposing (Item, decodeComment, ResponseList)
import Utils.Utils

import Debug exposing (log)

type alias Comment
  = { cid: Int
    , item: Item
    , depth: Int
    , shown: Bool
    , kids: Maybe Responses
    }
type Responses = Responses (List Comment)

type Msg
  = NoOp
  | GetComments Item
  | OnDataRetrieved (Result Http.Error ResponseList)
  | OnTime Time

type alias CommentsWidget
  = { curtime: Int
    , comments: Dict Int Comment
    }

init: CommentsWidget
init = {curtime= -1, comments=Dict.empty}

update: Msg -> CommentsWidget -> (CommentsWidget, Cmd Msg)
update msg widg
  = case msg of
    NoOp ->
      widg![]

    GetComments item ->
      widg![]

    OnDataRetrieved (Err e) ->
      let _ = log "OnDataRetrieved" e in
        widg![]

    OnDataRetrieved (Ok result) ->
      let
        kids = itemsToComments result.depth result.items
        parent = Dict.get result.parent widg.comments
        comments
          = case parent of
            Nothing -> widg.comments
            Just p -> Dict.insert result.parent {p|kids = Just (Responses kids)} widg.comments
        newcomments = insertComments result.depth kids comments
      in
      {widg|comments=newcomments}![Task.perform OnTime Time.now]

    OnTime t ->
      {widg| curtime = round <| t/1000}![]

itemsToComments: Int -> List Item -> List Comment
itemsToComments depth items
  = List.map(\i -> makeComment depth i) items

insertComments: Int -> List Comment -> Dict Int Comment -> Dict Int Comment
insertComments depth comments d
  = case comments of
    [] -> d
    c::rest ->
      insertComments depth rest (Dict.insert c.cid c d)

makeComment: Int -> Item -> Comment
makeComment depth item
  = {cid=item.id, item=item, depth=depth, shown=False, kids=Nothing}

getComments: Item -> Cmd Msg
getComments s
  = let url  = "http://localhost:3984/comments/" in
    Http.post url (Http.multipartBody [ Http.stringPart "pid" (toString s.id), Http.stringPart "cids" (toString s.kids)]) decodeComment
      |> Http.send OnDataRetrieved

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