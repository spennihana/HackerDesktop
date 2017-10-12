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
    NoOp ->
      model![]

    StoriesMsg smsg ->
      case msg of
      Widgets.Stories.ShowComments item ->  -- pass msg from the stories widget to the comments widget
        update CommentsMsg (Widgets.Comments.GetComments item) model

      _ ->
        let (swidg, scmd) = Widgets.Stories.update smsg model.storyWidget in
          {model| storyWidget = swidg}![Cmd.map StoriesMsg scmd]

    CommentsMsg cmsg ->
      let (cwidg, ccmd) = Widgets.Comments.update msg model.commentsWidget in
        {model|commentsWidget = cwidg}![Cmd.map CommentsMsg ccmd]