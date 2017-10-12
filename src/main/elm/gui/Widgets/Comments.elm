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
import Time

-- user imports
import Styles exposing (Styles(..))
import Utils.Decoders exposing (Item, decodeComment, ResponseList)
import Utils.Utils

import Debug exposing (log)

type alias Comment
  = { item: Item
    , depth: Int
    , shown: Bool
    , kids: Maybe Responses
    }
type Responses = Responses (List Comment)

type Msg
  = NoOp
  | GetComments Item
  | OnDataRetrieved (Result Http.Error (List Item))
  | OnTime

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
      let comments = unpackComments result.depth result.items widg.comments in
      {widg|comments=comments}![Task.perform OnTime Time.now]

    OnTime t ->
      {widg| curtime = round <| t/1000}![]


unpackComments: Int -> List Item -> Dict Int Comment -> Dict Int Comment
unpackComments depth comments d
  = case comments of
    [] -> d
    c::rest ->
      unpackComments depth rest (Dict.insert c.id (makeComment depth c))

makeComment: Int -> Item -> Comment
makeComment depth item
  = {item=item, depth=depth, shown=False, kids=Nothing}

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