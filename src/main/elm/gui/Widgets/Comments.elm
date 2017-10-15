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
import Element.Events exposing (onWithOptions, onClick)
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
  | ShowKids Comment
  | PrintComments

type alias CommentsWidget
  = { curtime: Int
    , comments: Dict Int Comment
    , root: Responses
    , type_: String
    , asktxt: Maybe String
    }

init: CommentsWidget
init = {curtime= -1, comments=Dict.empty, root=Responses [], type_="", asktxt=Nothing}

update: Msg -> CommentsWidget -> (CommentsWidget, Cmd Msg)
update msg widg
  = case msg of
    NoOp ->
      widg![]

    GetComments type_ item ->
      let
        asktxt
          = case type_ of
            "Ask" ->
              case item.text=="" of
              True -> Just item.title
              False-> Just item.text
            _ -> Nothing
      in
      {widg|type_=type_,asktxt=asktxt}![getComments type_ item]

    OnDataRetrieved (Err e) ->
      let _ = log "OnDataRetrieved" e in
        widg![]

    OnDataRetrieved (Ok result) ->
      case result.parent==0 of
      True ->
        widg![]
      False ->
        let
          kids = itemsToComments result.depth result.items
          parent = Dict.get result.parent widg.comments
          comments
            = case parent of
              Nothing -> widg.comments
              Just p -> Dict.insert result.parent {p|kids = Just (Responses kids)} widg.comments
          newcomments = insertComments kids comments
          root = updateRoot result.parent (Responses kids) widg.root
        in
        {widg|comments=newcomments, root=root}![Task.perform OnTime Time.now]

    ClearComments -> init![]

    OnTime t ->
      {widg| curtime = round <| t/1000}![]

    ShowKids c ->
      let
        newcomment = {c|shown=not c.shown}
        comments = Dict.insert c.cid newcomment widg.comments
        root = Responses (updateComment newcomment (Just widg.root))
        cmd = case c.kids of
              Nothing -> getComments widg.type_ c.item
              _ -> Cmd.none
      in
        {widg|comments=comments, root=root}![cmd]

    PrintComments ->
      let _ = log "printComments: " (printComments (Just widg.root)) in
      widg![]

printCommentsHelp: List Comment -> String
printCommentsHelp comments
  = case comments of
    [] -> ""
    x::xs ->
      (String.repeat (x.depth*2) " ") ++ (toString x.cid) ++ "\n" ++ (printComments x.kids) ++ (printCommentsHelp xs)

printComments: Maybe Responses -> String
printComments r
  = case r of
    Nothing -> ""
    Just (Responses comments) -> printCommentsHelp comments

itemsToComments: Int -> List Item -> List Comment
itemsToComments depth items
  = List.map(\i -> makeComment depth i) items

updateCommentHelp: Comment -> List Comment -> List Comment
updateCommentHelp c root
  = case root of
    [] -> []
    x::xs ->
      case x.cid == c.cid of
      True -> c::xs
      False->
        let
          kids = updateComment c x.kids
          newkids
            = case kids of
              [] -> Nothing
              x::xs -> Just (Responses kids)
        in
        {x| kids = newkids}::(updateCommentHelp c xs)

updateComment: Comment -> Maybe Responses -> List Comment
updateComment c root
  = case root of
    Nothing -> []
    Just (Responses comments) ->
      updateCommentHelp c comments

updateRootHelp: Int -> Responses -> List Comment -> List Comment
updateRootHelp pid newroot oldroot
  = case oldroot of
    [] ->
      oldroot
    x::xs ->
      case x.cid == pid of
      True -> {x|kids=Just newroot}::xs
      False ->
        case x.kids of
        Nothing -> x::(updateRootHelp pid newroot xs)
        Just r -> {x| kids = Just <| updateRoot pid newroot r}::(updateRootHelp pid newroot xs)

updateRoot: Int -> Responses -> Responses -> Responses
updateRoot pid newroot oldroot
  = case oldroot of
    Responses r ->
      case r of
      [] ->
        newroot
      _ ->
        Responses (updateRootHelp pid newroot r)

insertComments: List Comment -> Dict Int Comment -> Dict Int Comment
insertComments comments d
  = case comments of
    [] -> d
    c::rest ->
      insertComments rest (Dict.insert c.cid c d)

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
    Http.post url body (JDecode.oneOf[JDecode.null {parent=0,depth=0,items=[]}, decodeComment])
      |> Http.send OnDataRetrieved

view: CommentsWidget -> Element Styles v Msg
view cwidg
  = row None[moveRight 2, width fill, height fill]
      [comments cwidg]

header: CommentsWidget -> Element Styles v Msg
header cwidg
  = column CommentsHeader[]
    [ row None
        [ width fill
        , height <| px 100
        , padding 20
        ]
        [ el None[verticalCenter](
          case cwidg.asktxt of
          Nothing -> text "Comments"
          _ -> text "Ask HN: "
        )
        , row None
           [height fill, width fill, alignRight, verticalCenter, onClick PrintComments]
           [el Refresh
              [height <| px 30, width <| px 30
              ](node "i" <| el None [class "fa fa-refresh", center, verticalCenter] empty)]
        ]
    , row AskTxt[width fill, paddingXY 20 0][embedHtml <| asktxt cwidg]
    ]

asktxt: CommentsWidget -> String
asktxt cwidg
  = case cwidg.asktxt of
    Nothing -> ""
    Just t -> t

comments: CommentsWidget -> Element Styles v Msg
comments cwidg
  = case cwidg.root of
    Responses [] -> column None[width fill, height fill][header cwidg]
    Responses r ->
      column None
        [ width fill
        , height fill
        ][header cwidg, commentsHelper cwidg.curtime cwidg.root]

cmntsHelp: Int -> List Comment -> List (Element Styles v Msg)
cmntsHelp curtime comments
  = case comments of
    [] -> []
    x::xs ->
      case x.item.deleted of
      True -> cmntsHelp curtime xs
      False ->
        case x.shown of
        True -> (commentView curtime x)::(cmnts curtime x.kids)++(cmntsHelp curtime xs)
        False -> (commentView curtime x)::(cmntsHelp curtime xs)

cmnts: Int -> Maybe Responses -> List (Element Styles v Msg)
cmnts curtime r
  = case r of
    Nothing -> []
    Just (Responses comments) -> cmntsHelp curtime comments

commentsHelper: Int -> Responses -> Element Styles v Msg
commentsHelper curtime r
  = column None
      [ width fill
      , height fill
      , yScrollbar
      , xScrollbar
      ](cmnts curtime (Just r))

embedHtml: String -> Element Styles v Msg
embedHtml htmlStr
  = html <| Html.div[(Html.Attributes.property "innerHTML" (JEncode.string htmlStr))][]

commentView: Int -> Comment -> Element Styles v Msg
commentView curtime comment
  = column CommentStyle
      [ width fill
      , paddingXY 10 0
      ][ row None[width fill, spacing 20]
          [ column None[width <| px (toFloat <| comment.depth*20), height fill][empty]
          , column ShowCommentsStyle
              [ width <| px 20
              , height fill
              , center
              , verticalCenter
              , onClick <| ShowKids comment
              ](commentShowBtn comment)
          , column None
              [width fill, xScrollbar]
              [ row StoryItemHeader[][text comment.item.by, text " | ", text <| humanTime (toFloat<| curtime - comment.item.time)]
              , wrappedRow None[][embedHtml comment.item.text]
              , row None[alignRight][text <| (toString (cntResponses comment)) ++ " responses"]
              ]
          ]
       ]

cntResponses: Comment -> Int
cntResponses c
  = List.length c.item.kids

commentShowBtn: Comment -> List (Element Styles v Msg)
commentShowBtn c
  = let
      btnHtml
        = [ row None[spacing 5]
            [ column None [center, verticalCenter]
                [el ResponseCount[center, verticalCenter](text <| toString <| List.length c.item.kids)]
            , (node "i" <| el None [moveDown 1, class (getArrowType c)] empty)
            ]
          ]
    in
    case c.kids of
    Nothing ->
      case c.item.kids of
      [] -> [empty]
      _ -> btnHtml

    Just r ->
      case r of
      Responses kids ->
        case List.length kids of
        0 ->
          [empty]

        _ -> btnHtml

getArrowType:Comment -> String
getArrowType c
  = case c.shown of
    True -> "fa fa-angle-down"
    False -> "fa fa-angle-right"