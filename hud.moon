
{graphics: g, :keyboard} = love

class PaddedList
  new: (@x, @y, @padding=5) =>

  draw_next: (item, ...) =>
    item.x = @x
    item.y = @y
    item\draw ...
    @y += @padding + item.h

class Hud
  new: (@world) =>

  draw: =>
    {:player, :game, viewport: v} = @world
    g.push!
    g.translate v.x, v.y

    g.print "Hits: #{player.hits} - Ghost Bucks: #{game.money}", v\left(10), v\top(10)

    if next player.inventory
      list = PaddedList v\right(20), v\top(10)
      for item in *player.inventory
        list\draw_next item

    g.pop!

  update: (dt) =>


{ :Hud }
