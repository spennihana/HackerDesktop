module HNDTypes exposing (HNDMsg(..), HNDView(..))

import Widgets.Stories
import Widgets.Comments

type HNDMsg
  = NoOp
  | StoriesMsg Widgets.Stories.Msg
  | CommentsMsg Widgets.Comments.Msg

type HNDView
  = LoadingView -- app loading