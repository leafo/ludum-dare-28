
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

    g.print "Hits: #{player.hits} - Ghost Bucks: #{game.money}", 10, 10
    if next player.inventory
      list = PaddedList v\right(20), v\top(10)
      for item in *player.inventory
        list\draw_next item

  update: (dt) =>


{ :Hud }
