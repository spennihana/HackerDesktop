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

{-| Truncate float to dig digits -}
roundTo: Int -> Float -> Float
roundTo dig f=
  let
    a = round <| f*(toFloat <| 10^dig)
  in
    (toFloat a) / (toFloat <| 10^dig)

-- Callback from browser with window size
winsize : (Window.Size -> msg) -> Cmd msg
winsize msg = Task.perform msg Window.size

humanHours: Float -> String
humanHours elapsed_hours
  = (toString (roundTo 1 elapsed_hours)) ++ " hour(s) ago"

humanMinutes: Float -> String
humanMinutes elapsed_minutes
  = (toString <| round elapsed_minutes) ++ " minute(s) ago"

humanTime: Float -> String
humanTime elapsed_seconds
  = case elapsed_seconds / 3600 > 1 of
    True -> humanHours <| elapsed_seconds / 3600
    False -> case elapsed_seconds / 60 > 1 of
             True -> humanMinutes <| elapsed_seconds / 60
             False -> (toString elapsed_seconds) ++ " second(s) ago"

urlScrape: String -> String
urlScrape url
  = String.split "/" url
      |> List.drop 2
      |> List.head
      |> Maybe.withDefault ""