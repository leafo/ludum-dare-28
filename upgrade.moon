
{graphics: g, :keyboard} = love

import Label, AnimatedLabel, VList, ez_approach from require "ui"

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
