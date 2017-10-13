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
      case smsg of
      Widgets.Stories.ShowComments item ->  -- pass msg from the stories widget to the comments widget
        let (newmodel, _) = update (CommentsMsg (Widgets.Comments.ClearComments)) model in
        update (CommentsMsg (Widgets.Comments.GetComments (Widgets.Stories.type2Str model.storyWidget) item)) newmodel

      Widgets.Stories.ChangeStory _ ->
        let (swidg, scmd) = Widgets.Stories.update smsg model.storyWidget
            (newmodel, _) = update (CommentsMsg (Widgets.Comments.ClearComments)) model
        in
          {newmodel|storyWidget = swidg}![Cmd.map StoriesMsg scmd]

      _ ->
        let (swidg, scmd) = Widgets.Stories.update smsg model.storyWidget in
          {model| storyWidget = swidg}![Cmd.map StoriesMsg scmd]

    CommentsMsg cmsg ->
      let (cwidg, ccmd) = Widgets.Comments.update cmsg model.commentsWidget in
        {model|commentsWidget = cwidg}![Cmd.map CommentsMsg ccmd]