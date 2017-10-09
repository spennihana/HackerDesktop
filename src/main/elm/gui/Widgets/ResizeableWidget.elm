module Widgets.ResizeableWidget exposing (Widget, update, init, Msg(..), Resizer(..), subscriptions)

import Mouse exposing (Position)
import Utils.Constants exposing (..)
import Mouse exposing (Position)
import Html exposing (..)

import Debug exposing (log)

type Resizer = UpDown|LeftRight

type alias Widget a =
  { dinfo: DragInfo,
    -- custom widget props --
    widget: a
  }

type Msg
  = DragStart
  | DragPosition Position
  | DragEnd Position

subscriptions : Widget a -> Sub Msg
subscriptions w =
  Sub.batch [ if w.dinfo.dragging then Mouse.moves DragPosition else Sub.none,
              if w.dinfo.dragging then Mouse.ups   DragEnd      else Sub.none]

-- common widget init --
init: a -> Resizer -> (Position -> Int) -> Widget a
init widget resizer toP =
  let r = case resizer of
          UpDown    -> upDownResize
          LeftRight -> leftRightResize
  in
  { dinfo=dragInfoInit r toP,
    widget=widget
  }

update: Msg -> Widget a -> (Widget a, Cmd Msg)
update msg model =
  case msg of
    DragStart ->
     let
       dinfo = model.dinfo
       new_dinfo = {dinfo| dragging=True}
     in
       { model | dinfo=new_dinfo } ! []
    DragPosition p ->
      let
        dinfo = model.dinfo
        y0 = dinfo.y0
        v = dinfo.toP p
        h  = if y0== -1 then dinfo.h0 else (dinfo.resizer dinfo.h0 dinfo.y0 v)
        new_dinfo = {dinfo | y0 = clamp (dragmin+dragoff) (dragmax+dragoff) v, h0=clamp dragmin dragmax h}
      in {model | dinfo=new_dinfo} ! []
    DragEnd p ->
      let
        dinfo = model.dinfo
        new_dinfo = {dinfo | dragging = False}
      in {model | dinfo=new_dinfo } ! []

type alias DragInfo =
  { dragging: Bool,
    y0: Int,  -- initial height of window less the height/width
    h0: Int,  -- initial height of the log widget
    resizer: Int -> Int -> Int -> Int,
    toP: Position -> Int
  }

upDownResize: Int -> Int -> Int -> Int     -- delta_y == -delta_h => (y0 - y') == -(h0 - h') => h' = y0+h0-y'
upDownResize h0 y0 y_ = y0 + h0 - y_

leftRightResize: Int -> Int -> Int -> Int  -- delta_x
leftRightResize w0 x0 x_ = x_ + w0 - x0

dragInfoInit: (Int -> Int -> Int -> Int) -> (Position -> Int) -> DragInfo
dragInfoInit resizer toP
  = { dragging=False
    , y0= -1
    , h0=300
    , resizer=resizer
    , toP=toP
    }