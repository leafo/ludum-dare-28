

{graphics: g, :keyboard, :timer} = love

import VList, BlinkingLabel from require "ui"

class Title
  new: =>
    @bg = imgfy "images/title.png"
    @ghost = imgfy "images/title_ghost.png"
    @viewport = Viewport scale: 3

    @entities = DrawList!

    @entities\add VList 10, 50, {
      BlinkingLabel "Press Enter", 10, 50
      BlinkingLabel "To Begin", 10, 50
    }

  on_show: =>
    sfx\play_music "ghost_title"

  on_key: (key) =>
    if key == "return"
      sfx\play "start_game"
      dispatcher\push Game!

  draw: =>
    @viewport\apply!
    @bg\draw 0,0

    COLOR\pusha 225
    @ghost\draw @viewport\right(-30) - @ghost\width!,
      10 + math.sin(timer.getTime!) * 10, 0, 0.8, 0.8
    COLOR\pop!

    @entities\draw!
    @viewport\pop!

  update: (dt) =>
    @entities\update dt

{:Title}

