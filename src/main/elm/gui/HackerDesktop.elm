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
init = AppModel.init ! [Cmd.map StoriesMsg Widgets.Stories.loadContent]

subscriptions: HNDModel -> Sub HNDMsg
subscriptions model
  = Sub.batch
    [ Sub.map StoriesMsg (Widgets.Stories.subscriptions model.storyWidget)
    ]