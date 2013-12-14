
{graphics: g, :keyboard} = love

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
    g.print @is_func and @_text or @text, @x, @y

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

  update: (dt) =>
    @seqs\update dt
    @entities\update dt, @

  on_key: (key) =>
    if key == "return"
      @game\on_new_round!
      dispatcher\pop!

  draw: =>
    @viewport\apply!
    @entities\draw!
    @viewport\pop!

{ :Upgrade }
