module Styles exposing (..)

import Style exposing (..)
import Style.Border as Border
import Style.Color
import Color
import Style.Font as Font
import Style.Shadow

type Styles
  =
    -- main styles
    None
  | Root
  | Stories
  | Dragger
  | DraggerInner
  | Header
  | StoriesHeader
  | CommentsHeader
  | Items
  | Sidebar
  | SidebarButton SidebarButtonStyles
  | Refresh
  | StoryItem
  | StoryItemHeader
  | CommentBubbleWrapper
  | CommentStyle
  | CommentBubble
  | StoryItemTitle

type SidebarButtonStyles
  = Selected
  | Normal

sidebarBtnStyles: List (Property Styles v)
sidebarBtnStyles =
  [ Style.Color.background Color.darkBlue
  , Border.all 2
  , Style.cursor "pointer"
  , Border.rounded 3
  , Font.size 20
  , Style.Color.text Color.white
  , Style.Color.border <| Color.hsla 0 0 0 0  -- hidden background
  , hover [ Style.Color.border <| Color.grayscale 0.30]
  ]

panelItemStyles: List (Property Styles v)
panelItemStyles =
  [ Style.Color.text Color.gray
  , Font.size 20
  , Style.cursor "pointer"
  ]

appstyles: StyleSheet Styles v
appstyles =
  Style.styleSheet
    [ style None []
    , style Root []
    , style Stories []
    , style Dragger [Style.cursor "ew-resize"]
    , style DraggerInner [Style.Color.background Color.black]


    , style Header [Style.prop "-webkit-app-region" "drag", Font.size 30]
    , style StoriesHeader
        [ Style.prop "-webkit-app-region" "drag"
        , Font.size 30
        , Style.Color.background Color.lightGray
        ]
    , style CommentsHeader
        [ Style.prop "-webkit-app-region" "drag"
        , Font.size 30
        , Border.bottom 1
        , Style.Color.border Color.lightGray
        ]
    , style Sidebar [ Style.prop "-webkit-user-select" "none"
                    , Style.Color.background <| Color.rgb 255 112 23
                    ]
    , style (SidebarButton Normal) sidebarBtnStyles
    , style (SidebarButton Selected) <| sidebarBtnStyles ++ [Style.Color.background <| Color.complement (Color.rgb 255 112 23)]
    , style Refresh
        [ Style.Color.text Color.green
        , Font.size 20
        , Style.cursor "pointer"
        , Style.Color.background <| Color.hsla 0 0 0 0
        , Border.rounded 5
        , hover [Style.Color.text Color.white, Style.Color.background <| Color.rgba 115 210 22 0.60]
        ]
    , style Items[]
    , style StoryItem[Border.bottom 1]
    , style StoryItemHeader[Font.size 13, Style.Color.text Color.lightCharcoal]
    , style StoryItemTitle[Font.size 18, Style.Color.text Color.black]
    , style CommentBubbleWrapper[Font.size 15, Style.cursor "pointer"]
    , style CommentBubble[Font.size 18, Style.Color.text Color.black]
    , style CommentStyle[Border.bottom 1]
    ]