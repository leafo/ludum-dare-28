
{graphics: g, :keyboard} = love

ez_approach = (val, target, dt) ->
  approach val, target, dt * 10 * math.max 1, math.abs val - target

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

  draw: =>
    {:player, :game, viewport: v} = @world
    g.push!
    g.translate v.x, v.y

    str = table.concat {
      "HIT: #{player.hits}"
      "HP: #{player.health}"
      "GHOST BUCKS: #{math.floor @display_money}"
    }, " "

    g.print str, v\left(10), v\top(10)

    if next game.inventory
      list = PaddedList v\right(20), v\top(10)
      for item in *game.inventory
        list\draw_next item

    g.pop!

  update: (dt) =>
    { :player, :game } = @world
    @display_money = ez_approach @display_money, game.money, dt

{ :Hud }
