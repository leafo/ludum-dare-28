

{graphics: g, :keyboard, :timer} = love

import Label, VList, BlinkingLabel, RevealLabel from require "ui"

local *

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
      dispatcher\push Tutorial! -- Game\new_game_state!

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


class BaseScreen
  new: =>
    @viewport = Viewport scale: 3
    @entities = DrawList!

  update: (dt) =>
    @entities\update dt

  draw_inner: =>

  draw: (fn=@draw_inner) =>
    @viewport\apply!
    fn @ if fn
    @entities\draw!
    @viewport\pop!

class BeginNight extends BaseScreen


class Tutorial extends BaseScreen
  dialog: {
    "Greetings Fellow Ghost"
    "This is a dialog"
  }

  new: =>
    super!
    @dialog_list = VList 0,0
    @entities\add @dialog_list

    add_str = (msg, callback) ->
      table.insert @dialog_list.items, RevealLabel msg, 0,0, callback

    @entities\add Sequence ->
      for line in *@dialog
        print "Adding line"
        await add_str, line
        wait 0.2


{:Title}

