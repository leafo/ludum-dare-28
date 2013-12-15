
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
    true

  draw: =>
    text = @is_func and @_text or @text
    g.print text, @x, @y

    -- COLOR\push 255,100,100, 200
    -- g.rectangle "fill", @x,@y, 2,2
    -- g.rectangle "fill", @x+@w,@y+@h, 2,2
    -- COLOR\pop!


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


class BlinkingLabel extends Label
  rate: 1.2
  duty: 0.8 -- percent of time visible

  elapsed: 0

  update: (dt) =>
    @elapsed += dt
    super dt

  draw: =>
    scaled = @elapsed / @rate
    p = scaled - math.floor scaled

    if p <= @duty
      super!

class RevealLabel extends Label
  rate: 0.05

  new: (text, @x, @y, fn) =>
    @chr = 0
    @seq = Sequence ->
      while @chr < #text
        @chr += 1
        wait @rate

      @done = true
      @seq = nil
      fn! if fn

    @set_text -> text\sub 1, @chr

  update: (dt) =>
    @seq\update dt if @seq
    super dt


class BaseList
  padding: 5
  xalign: "left"
  yalign: "top"
  w: 0
  h: 0

  -- can pass instance properties into items
  new: (@x, @y, @items) =>
    -- not specifying position
    if type(@x) == "table"
      @items = @x
      @x = 0
      @y = 0

    -- extract props
    for k,v in pairs @items
      if type(k) == "string"
        @items[k] = nil
        @[k] = v

  update_size: -> error "override me"

  update: (dt, ...) =>
    for item in *@items
      item\update dt, ...
    @update_size!
    true

class VList extends BaseList
  update_size: =>
    @w, @h = 0, 0
    for item in *@items
      @h += item.h + @padding
      if item.w > @w
        @w = item.w

    @h -= @padding if @h > 0

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

class HList extends BaseList
  update_size: =>
    @w, @h = 0, 0
    for item in *@items
      @w += item.w + @padding
      if item.h > @h
        @h = item.h

    @w -= @padding if @w > 0

  draw: =>
    {:x, :y} = @

    for item in *@items
      item.x = x
      item.y = y
      x += @padding + item.w
      item\draw!


{
  :Label, :AnimatedLabel, :BlinkingLabel, :RevealLabel, :VList, :HList,
  :ez_approach
}

