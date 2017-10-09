module HackerDesktop exposing (..)

-- sys imports
import Task
import Html exposing (program)
-- user imports
import HNDTypes exposing (HNDMsg(..), HNDView(..))
import AppModel exposing (HNDModel)
import AppUpdate exposing (update)
import AppView exposing (view)
import Widgets.Stories

import Debug exposing (log)

main: Program Never HNDModel HNDMsg
main = Html.program { init = init, update=update, view=view, subscriptions=subscriptions}

init: (HNDModel, Cmd HNDMsg)
init =
  let hndmodel = AppModel.init in
    hndmodel![Cmd.map StoriesMsg <| Widgets.Stories.loadContent hndmodel.storyWidget]

subscriptions: HNDModel -> Sub HNDMsg
subscriptions model
  = Sub.batch
    [ Sub.map StoriesMsg (Widgets.Stories.subscriptions model.storyWidget)
    ]