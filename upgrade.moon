
{graphics: g, :keyboard} = love

-- a piece of text that knows its size
class Label extends Box
  new: (text, @x=0, @y=0) =>
    @update_text text

  update_text: (@text) =>
    font = g.getFont!
    @w = font\getWidth @text
    @h = font\getHeight!

  update: (dt) =>

  draw: =>
    g.print @text, @x, @y

class VList
  padding: 5
  xalign: "left"

  new: (@x, @y, @items) =>

  draw: =>
    {:x, :y} = @

    for item in *@items
      item.x = if @xalign == "right"
        x - item.w
      else
        x

      item.y = y
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
