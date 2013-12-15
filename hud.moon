
{graphics: g, :keyboard} = love

import ez_approach, HList, Label from require "ui"

class PaddedList
  new: (@x, @y, @padding=5) =>

  draw_next: (item, ...) =>
    item.x = @x
    item.y = @y
    item\draw ...
    @y += @padding + item.h

class Hud
  new: (@world) =>
    @display_money = @world.game.money
    @entities = DrawList!

    {viewport: v} = @world

    @entities\add HList v\top(5), v\left(5), {
      Label -> "HIT: #{@world.player.hits}"
      Label -> "HP: #{@world.player.hits}"
      Label -> "$#{math.floor @display_money}"
    }, padding: 20

  draw: =>
    {:player, :game, viewport: v} = @world

    g.push!
    g.translate v.x, v.y

    if next game.inventory
      list = PaddedList v\right(20), v\top(10)
      for item in *game.inventory
        list\draw_next item

    @entities\draw v, @
    g.pop!

  add: (...) => @entities\add ...

  update: (dt) =>
    { :player, :game } = @world
    @entities\update dt
    @display_money = ez_approach @display_money, game.money, dt

{ :Hud, :ez_approach }
