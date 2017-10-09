module Utils.Utils exposing (..)

import Task
import Html exposing (Attribute)
import Html.Events exposing (onWithOptions)
import Json.Decode as JDecode
import Window

doTask: msg -> Cmd msg
doTask m = Task.perform (\_ -> m) (Task.succeed always)

type alias ClickOptions = { preventDefault : Bool, stopPropagation : Bool }
clickOptionsTT : ClickOptions
clickOptionsTT = {preventDefault=True, stopPropagation=True}
clickOptionsTF : ClickOptions
clickOptionsTF = {preventDefault=True, stopPropagation=False}
clickOptionsFT : ClickOptions
clickOptionsFT = {preventDefault=False, stopPropagation=True}
clickOptionsFF : ClickOptions
clickOptionsFF = {preventDefault=False, stopPropagation=False}

{-| Thousands printing of integers -}
prettyInt : Char -> Int -> String
prettyInt sep n =
  let ni = abs n
      nis = String.join (String.fromChar sep) (chunksOfRight 3 <| toString ni)
  in  if n < 0
      then String.cons '-' nis
      else nis

chunksOfRight : Int -> String -> List String
chunksOfRight k s =
  let len = String.length s
      k2 = 2 * k
      chunksOfR s_ =
        if String.length s_ > k2
        then String.right k s_ :: chunksOfR (String.dropRight k s_)
        else String.right k s_ :: [String.dropRight k s_]
  in  if len > k2 then
          List.reverse (chunksOfR s)
      else if len > k then
          String.dropRight k s :: [String.right k s]
      else
          [s]

-- Callback from browser with window size
winsize : (Window.Size -> msg) -> Cmd msg
winsize msg = Task.perform msg Window.size