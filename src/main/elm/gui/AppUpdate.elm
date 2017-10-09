module AppUpdate exposing (update)

import Task
-- user imports
import HNDTypes exposing (HNDMsg(..), HNDView(..))
import AppModel exposing (HNDModel)
import Widgets.Stories
import Widgets.Comments

import Debug exposing (log)


update: HNDMsg -> HNDModel -> (HNDModel, Cmd HNDMsg)
update msg model =
  case msg of
    NoOp -> model ! []
    StoriesMsg smsg ->
      let
        (swidg, scmd) = Widgets.Stories.update smsg model.storyWidget
      in
        {model| storyWidget = swidg}![Cmd.map StoriesMsg scmd]
    CommentsMsg cmsg -> model ![]