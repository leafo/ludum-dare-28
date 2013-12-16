
{graphics: g, :keyboard} = love

import ez_approach, HList, VList, Label from require "ui"

class Heart extends Box
  lazy sprite: -> Spriter("images/tiles.png")
  w: 11
  h: 10

  new: =>
    @x = 0
    @y = 0

  draw: =>
    @sprite\draw "32,192,11,10", @x, @y

  update: =>

class Hud
  new: (@world) =>
    @display_money = @world.game.money
    @entities = DrawList!

    {viewport: v} = @world

    @heart = Heart!
    @heart_list = HList {
      padding: 2
    }

    @inventory_list = HList { padding: 2 }

    @entities\add VList v\left(5), v\top(5), {
      padding: 2

      Label -> "HAUNTS: #{@world.player.hits}"
      @heart_list
    }

    @entities\add VList v\right(5), v\top(5), {
      padding: 5
      xalign: "right"

      Label -> "$#{math.floor @display_money}"
      @inventory_list
    }

  draw: =>
    {:player, :game, viewport: v} = @world

    g.push!
    g.translate v.x, v.y

    @inventory_list.items = game.inventory

    @entities\draw v, @
    g.pop!

  add: (...) => @entities\add ...

  show_message_box: (mbox) =>
    if @msg_box and @msg_box.visible
      @msg_box\hide!

    @msg_box = mbox
    @entities\add mbox

  update: (dt) =>
    { :player, :game } = @world

    -- update heart list
    if #@heart_list.items != player.health
      @heart_list.items = [@heart for i=1,player.health]

    @entities\update dt
    @display_money = ez_approach @display_money, game.money, dt

{ :Hud, :ez_approach }
