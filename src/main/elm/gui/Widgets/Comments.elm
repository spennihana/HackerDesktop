module Widgets.Comments exposing (..)


-- sys imports
import Dict exposing (Dict)
import Html exposing (Html)
import Element exposing (Element, column, text, el, empty, node, row, wrappedRow,
                         wrappedColumn, newTab,
                         paragraph, textLayout, full, html)
import Element.Attributes exposing (px, padding, height, fill, width, fill, vary,
                                    toAttr, verticalCenter, center, spacing, id,
                                    percent, alignRight, alignBottom, moveDown, classList, class,
                                    alignLeft, paddingXY, attribute, yScrollbar, xScrollbar,
                                    moveLeft, moveRight
                                    )
import Element.Events exposing (onWithOptions)
import Element.Input
import Json.Decode as JDecode
import Json.Encode as JEncode
import Time exposing (Time)
import Task
import Http
import Html.Attributes

-- user imports
import Styles exposing (Styles(..))
import Utils.Decoders exposing (Item, decodeComment, ResponseList)
import Utils.Utils exposing (humanTime)

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
  | GetComments String Item
  | OnDataRetrieved (Result Http.Error ResponseList)
  | OnTime Time
  | ClearComments

type alias CommentsWidget
  = { curtime: Int
    , comments: Dict Int Comment
    , root: Responses
    }

init: CommentsWidget
init = {curtime= -1, comments=Dict.empty, root=Responses []}

update: Msg -> CommentsWidget -> (CommentsWidget, Cmd Msg)
update msg widg
  = case msg of
    NoOp ->
      widg![]

    GetComments type_ item ->
      widg![getComments type_ item]

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
        root = updateRoot result.parent (Responses kids) widg.root
      in
      {widg|comments=newcomments, root=root}![Task.perform OnTime Time.now]

    ClearComments -> init![]

    OnTime t ->
      {widg| curtime = round <| t/1000}![]

itemsToComments: Int -> List Item -> List Comment
itemsToComments depth items
  = List.map(\i -> makeComment depth i) items

updateRootHelp: Int -> Responses -> List Comment -> List Comment
updateRootHelp pid newroot oldroot
  = case oldroot of
    [] ->
      oldroot
    x::xs ->
      case x.cid == pid of
      True -> {x|kids=Just newroot}::xs
      False -> x::(updateRootHelp pid newroot xs)

updateRoot: Int -> Responses -> Responses -> Responses
updateRoot pid newroot oldroot
  = case oldroot of
    Responses r ->
      case r of
      [] ->
        newroot
      _ ->
        Responses (updateRootHelp pid newroot r)

insertComments: Int -> List Comment -> Dict Int Comment -> Dict Int Comment
insertComments depth comments d
  = case comments of
    [] -> d
    c::rest ->
      insertComments depth rest (Dict.insert c.cid c d)

makeComment: Int -> Item -> Comment
makeComment depth item
  = {cid=item.id, item=item, depth=depth, shown=False, kids=Nothing}

getComments: String -> Item -> Cmd Msg
getComments type_ s
  = let url = "http://localhost:3984/comments"
        obj = JEncode.object
              [ ("story", JEncode.string <| String.toLower type_)
              , ("pid", JEncode.string <| toString s.id)
              , ("cids", JEncode.string <| toString s.kids)
              ]
        body = Http.stringBody "application/json" (JEncode.encode 0 obj)
    in
    Http.post url body decodeComment
      |> Http.send OnDataRetrieved

view: CommentsWidget -> Element Styles v Msg
view cwidg
  = row None[moveRight 2, width fill, height fill]
      [comments cwidg]

header: CommentsWidget -> Element Styles v Msg
header cwidg
  = row CommentsHeader
      [ width fill
      , height <| px 100
      , padding 20
      ]
      [ el None[verticalCenter](text "Comments")
      , row None
         [height fill, width fill, alignRight, verticalCenter]
         [el Refresh
            [height <| px 30, width <| px 30
            ](node "i" <| el None [class "fa fa-refresh", center, verticalCenter] empty)]
      ]

comments: CommentsWidget -> Element Styles v Msg
comments cwidg
  = case cwidg.root of
    Responses [] -> column None[][empty]
    Responses r ->
      column None
        [ width fill
        , height fill
        ][header cwidg, commentsHelper cwidg.curtime r]

commentsHelper: Int -> List Comment -> Element Styles v Msg
commentsHelper curtime r
  = column None
      [ width fill
      , height fill
      , yScrollbar
      ](showComments curtime r)

showComments: Int -> List Comment -> List (Element Styles v Msg)
showComments curtime comments
  = case comments of
    [] -> []
    x::xs ->
      case x.item.deleted of
      True -> showComments curtime xs  -- don't show deleted comments
      False -> (commentView curtime x)::(showComments curtime xs)

embedHtml: String -> Element Styles v Msg
embedHtml htmlStr
  = html <| Html.div[(Html.Attributes.property "innerHTML" (JEncode.string htmlStr))][]

commentView: Int -> Comment -> Element Styles v Msg
commentView curtime comment
  = column CommentStyle
      [ width fill
      , paddingXY 10 0
      ][ row None[width fill, spacing 20]
          [ column ShowCommentsStyle[width <| px 20, height fill, center, verticalCenter](commentShowBtn comment)
          , column None
              [width fill, moveRight (toFloat <| comment.depth*10)]
              [ row StoryItemHeader[][text comment.item.by, text " | ", text <| humanTime (toFloat<| curtime - comment.item.time)]
              , row None[][embedHtml comment.item.text]
              , row None[alignRight][text <| (toString (cntResponses comment)) ++ " responses"]
              ]
          ]
       ]

cntResponses: Comment -> Int
cntResponses c
  = List.length c.item.kids

commentShowBtn: Comment -> List (Element Styles v Msg)
commentShowBtn c
  = case c.kids of
    Nothing ->
      case c.item.kids of
      [] -> [empty]
      _ ->
        [ row None[spacing 2]
            [ column None [center, verticalCenter][(text <| toString <| List.length c.item.kids)]
            , (node "i" <| el None [class "fa fa-angle-right"] empty)
            ]
        ]

    Just r ->
      case r of
      Responses kids ->
        case List.length kids of
        0 ->
          [empty]

        _ ->
          [ el None []
             (node "i" <| el None [class (getArrowType c)] empty)
          , el None [](text <| toString <| List.length kids)
          ]

getArrowType:Comment -> String
getArrowType c
  = case c.shown of
    True -> "fa fa-angle-down"
    False -> "fa fa-angle-right"