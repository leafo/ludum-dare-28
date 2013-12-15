
{graphics: g, :keyboard} = love

import ez_approach from require "hud"

-- a piece of text that knows its size
class Label extends Box
  new: (text, @x=0, @y=0) =>
    @set_text text

  set_text: (@text) =>
    @is_func = type(@text) == "function"
    @_set_size @text unless @is_func
    @_update_from_fun!

  _set_size: (text) =>
    font = g.getFont!
    @w = font\getWidth text
    @h = font\getHeight!

  _update_from_fun: =>
    if @is_func
      @_text = @text!
      @_set_size @_text

  update: (dt) =>
    @_update_from_fun!

  draw: =>
    text = @is_func and @_text or @text
    g.print text, @x, @y

-- has effect list
class AnimatedLabel extends Label
  new: (...) =>
    super ...
    @effects = EffectList!

  update: (dt) =>
    @effects\update dt
    super dt

  draw: =>
    text = @is_func and @_text or @text

    g.push!
    g.translate @x, @y
    @effects\before!
    g.print text, -@w/2, -@h/2
    @effects\after!
    g.pop!


class VList
  padding: 5
  xalign: "left"
  yalign: "top"

  new: (@x, @y, @items) =>

  draw: =>
    {:x, :y} = @

    dy = if @yalign == "bottom"
      total_height = 0
      for item in *@items
        total_height += item.h

      if total_height > 0
        total_height += @padding * #@items

      -total_height
    else
      0

    for item in *@items
      item.x = if @xalign == "right"
        x - item.w
      else
        x

      item.y = y + dy
      y += @padding + item.h
      item\draw!

  update: (dt, ...) =>
    for item in *@items
      item\update dt, ...
    true

class Upgrade
  new: (@game) =>
    @viewport = Viewport scale: 2
    @entities = DrawList!
    @seqs = DrawList!

    @display_money = @game.money
    @money_last_round = @game.money_this_round

    @entities\add with VList @viewport\right(10), 10, {
      Label "Nice scare!"
      Label "You earned $#{@money_last_round} last round"
      Label "Press enter to continue"
    }
      .xalign = "right"

    @entities\add with VList 10, @viewport\bottom(10), {
      Label "1 - Buy Hit"
      Label "2 - Buy Health"
    }
      .yalign = "bottom"


    @money_label = AnimatedLabel -> "$#{math.floor @display_money} GB"

    @entities\add with VList @viewport\right(10), @viewport\bottom(10), {
      @money_label
    }
      .yalign = "bottom"
      .xalign = "right"

  update: (dt) =>
    @seqs\update dt
    @entities\update dt, @
    @display_money = ez_approach @display_money, @game.money, dt

  on_key: (key) =>
    try_upgrade = (name) ->
      price =  @game\upgrade_price name

      if @game.money > price
        @game.money -= price
        @game.upgrades[name] += 1
      else
        @money_label.effects\add ShakeEffect 0.5
        sfx\play "buzz"

    switch key
      when "return"
        @game\on_new_round!
        dispatcher\pop!
      when "1" -- buy hit
        try_upgrade "hit"
      when "2" -- buy hp
        try_upgrade "hp"

  draw: =>
    @viewport\apply!
    @entities\draw!
    @viewport\pop!

{ :Upgrade }
