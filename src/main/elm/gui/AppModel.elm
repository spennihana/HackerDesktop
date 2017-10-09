module AppModel exposing (HNDModel, init)

-- user imports
import HNDTypes exposing (HNDView(..))
import Widgets.Stories exposing (StoriesWidget)
import Widgets.Comments exposing (CommentsWidget)

type alias HNDModel =
  { storyWidget: StoriesWidget
  , commentsWidget: CommentsWidget
  , view: HNDView
  }

init: HNDModel
init = {storyWidget = Widgets.Stories.init, commentsWidget = Widgets.Comments.init, view=LoadingView}