
{graphics: g, :keyboard} = love

ez_approach = (val, target, dt) ->
  approach val, target, dt * 10 * math.max 1, math.abs val - target

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
    hw = @w/2
    hh = @h/2

    g.push!
    g.translate @x + hw, @y + hh
    @effects\before!
    g.print text, -hw, -hh
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

{:Label, :AnimatedLabel, :VList, :ez_approach}

