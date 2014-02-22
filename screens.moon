

{graphics: g, :keyboard, :timer} = love

import Label, VList, BlinkingLabel, RevealLabel from require "ui"

local *

class Title
  new: =>
    @bg = imgfy "images/title.png"
    @ghost = imgfy "images/title_ghost.png"
    @viewport = Viewport VIEWPORT_OPTS

    @entities = DrawList!

    @entities\add VList 10, 50, {
      BlinkingLabel "Press Enter", 10, 50
      BlinkingLabel "To Begin", 10, 50
    }

  on_show: =>
    sfx\play_music "ghost_title"

  on_key: (key) =>
    if controller\is_down "confirm"
      sfx\play "start_game"
      dispatcher\push Tutorial!

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
    @viewport = Viewport VIEWPORT_OPTS
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

join = (strs) ->
  table.concat strs, "\n"


class TextScreen extends BaseScreen
  dialog: {}

  new: =>
    super!

    add_str = (str, callback) ->
      with l = RevealLabel str, 10,10, callback
        @entities\add l

    @entities\add Sequence ->
      for msg in *@dialog
        label = await add_str, msg
        wait_for_key "return"
        label.alive = false

      @next_screen!


  on_key: (key) =>
    if controller\is_down "cancel"
      @next_screen!
      return true

class Tutorial extends TextScreen
  dialog: {
    join {
      "Greetings fellow ghost!"
      "Times are tough."
      ""
      "Press Enter..."
      "(Esc skips tutorial)"
    }

    join {
      "You need to head to the"
      "human world to get some"
      "ghost bucks."
      ""
      "Press Enter..."
    }

    join {
      "Haunt humans to steal"
      "their money. Watch out"
      "for evil ghosts."
      ""
      "Press Enter..."
    }

    join {
      "You only have one"
      "haunt in you, so get"
      "some money to upgrade."
      ""
      "Press Enter..."
    }


    join {
      "Arrow keys move"
      "'X' haunts"
      "'C' opens doors"
      ""
      "Press Enter to start"
    }

  }

  next_screen: =>
    dispatcher\push Game\new_game_state!

class WinGame extends TextScreen
  dialog: {
    join {
      "Congratulations!"
      "You beat the game"
      ""
      "Press Enter..."
    }

    join {
      "I ran out of time"
      "so this is all you"
      "get!"
      ""
      "Thanks for playing"
      ""
      "Press Enter"
    }

  }

  next_screen: =>
    dispatcher\replace Title!

{:Title, :WinGame}

