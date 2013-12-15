
require "lovekit.all"
require "lovekit.reloader"

{graphics: g, :keyboard} = love

import Upgrade from require "upgrade"
import Hud from require "hud"
import Enemy from require "enemy"

local *

class MessageBox
  padding: 5
  visible: true

  new: (@text) =>
    @alpha = 0
    @seq = Sequence ->
      tween @, 0.3, { alpha: 255 }
      @seq = nil

  draw: (viewport) =>
    left = viewport\left 10
    right = viewport\right 10
    bottom = viewport\bottom 10

    font = g.getFont!
    height = font\getHeight!
    width = right - left

    x = left
    y = bottom - height

    COLOR\pusha @alpha
    g.push!
    g.translate x, y
    g.rectangle "fill", 0, 0, width, height
    g.print @text, 0,0
    g.pop!
    COLOR\pop!

  hide: =>
    @seq = Sequence ->
      tween @, 0.2, { alpha: 0 }
      @visible = false

  update: (dt) =>
    @seq\update dt if @seq
    @visible

class DoorBox extends Box
  w: 30
  h: 30

  new: (x,y, @to) =>
    @move_center x,y
    @touching = 0

  draw: =>
    super {255, 100, 255,100}

  can_enter: (game) =>
    for i, item in ipairs game.inventory
      if item.__class == Key
        return item, i

  on_hit: (entity, world) =>
    if entity.is_player
      unless @message_box
        msg = if @can_enter world.game
          "Press 'Return' to enter the door"
        else
          "You need a key to enter the door"

        @message_box = MessageBox msg
        world.hud\add @message_box

      @touching = 2

  update: (dt) =>
    if @touching > 0
      @touching -= 1

    if @touching == 0 and @message_box
      @message_box\hide!
      @message_box = nil

    true

class Key extends Entity
  w: 5
  h: 5
  on_ground: true
  collectable: false

  new: (x,y, vel) =>
    super x, y
    @vel = vel

  on_hit: (entity, world) =>
    return if @vel\len! > 10
    return unless entity.is_player
    @on_ground = false
    table.insert world.game.inventory, @

  draw: =>
    super {255, 255, 100}

  update: (dt, world) =>
    return false unless @on_ground

    dampen_vector @vel, dt * 200

    cx,cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = -@vel[1]
    if cy
      @vel[2] = -@vel[2]

    true

class FadeAway
  time: 0.8
  new: (@entity, @done_fn) =>
    @life = @time

  draw: =>
    p = smoothstep 0,1, 1 - math.max @life/@time, 0
    drift = p * 10
    sway = (p + 0.5) * 5 * math.sin (@time - @life) * 10

    COLOR\pusha (1 - p) * 255
    x, y = @entity\center!
    g.push!
    g.translate x + sway, y - drift
    g.scale p + 1, p + 1
    g.translate -x,-y
    @entity\draw!
    g.pop!

    COLOR\pop!

  update: (dt) =>
    @life -= dt
    dampen_vector @entity.vel, dt * 400
    @entity\move unpack @entity.vel * dt

    if @life <= 0
      @done_fn and @done_fn @
      false
    else
      true

class MoneyEmitter extends Emitter
  class MoneyP extends PixelParticle
    size: 4

  class MoneyTextEmitter extends TextEmitter
    speed: 200

    make_particle: (...) =>
      with super ...
        .vel = Vec2d(0,-1)\random_heading(30) * @speed
        .accel = Vec2d 0, @speed*2
        .dspin = rand -2,2
        .dscale = rand 1.1, 1.2

  new: (amount, world, ...) =>
    super world, ...
    world.entities\add MoneyTextEmitter "+$#{amount}", world, ...

  count: 10
  make_particle: (x,y) =>
    power = rand 0.8, 1.1
    dx = 5 * rand -0.5, 0.5
    dy = 5 * rand -0.5, 0.5

    MoneyP x + dx, y + dy,
      Vec2d(0, -180)\random_heading(30) * power,
      Vec2d(0, 300)

class ScareParticle extends Box
  life: 1
  used: false -- has hit something

  new: (@player, ...)=>
    super ...

  draw: =>
    super {255,255, 0, 128}

  update: (dt, world) =>
    @life -= dt
    @life > 0

  on_hit: (entity, world) =>
    return if @used
    return unless entity.on_scare
    return if entity.is_scared
    entity\on_scare world
    @used = true

class Human extends Entity
  is_human: true
  is_scared: false
  has_key: true

  draw: =>
    if @is_scared
      super {100,255,255}
    else
      super {100,255,100}

  on_scare: (world) =>
    @is_scared = true
    center = Vec2d @center!
    amt = 10

    world.entities\add MoneyEmitter amt, world, unpack center
    world.game\give_money amt

    if @has_key
      dir = Vec2d(world.player\center!) - center
      dir = dir\normalized!\random_heading!
      world.entities\add Key @x, @y, dir * 150 * rand(1, 1.3)

  update: (...) =>
    super ...
    true

class Player extends Entity
  is_player: true

  hits: 1
  health: 1

  speed: 20
  max_speed: 100

  new: (x,y) =>
    @seqs = DrawList!
    @accel = Vec2d 0, 0
    super x,y

  scare: (world) =>
    return if @scare_cooloff
    reutrn unless @hits > 0

    @scare_cooloff = true

    radius = ScareParticle @, @scale(2, 2, true)\unpack!
    world.entities\add radius
    @hits -= 1

    @seqs\add Sequence\after 0.3, ->
      @scare_cooloff = false

  on_die: (world, complete) =>
    world.entities\add FadeAway @, complete

  on_hit: (entity, world) =>
    return if @stunned
    if entity.is_enemy
      @health -= 1
      if @health <= 0
        world\kill_player!

      @vel = entity\vector_to(@)\normalized! * 150
      world.viewport\shake!
      @stunned = true
      @seqs\add Sequence\after 0.1, ->
        @stunned = false

  draw: =>
    if @stunned
      super {200,200,200}
    else
      super {255,255,255}

  update: (dt, world) =>
    @seqs\update dt
    decel = @speed * 10 * dt
    @accel = movement_vector! * @speed

    if @stunned
      decel *= 4
      @accel = Vec2d!

    if @accel\is_zero!
      dampen_vector @vel, decel
    else
      if @accel[1] == 0
        -- not moving in x, shrink it
        @vel[1] = dampen @vel[1], decel
        nil
      else
        if (@accel[1] < 0) == (@vel[1] > 0)
          @accel[1] *= 2

      if @accel[2] == 0
        -- not moving in y, shrink it
        @vel[2] = dampen @vel[2], decel
      else
        if (@accel[2] < 0) == (@vel[2] > 0)
          @accel[2] *= 2

    @vel\adjust unpack @accel * dt * @speed
    @vel\cap @max_speed

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = -@vel[1]/2
    if cy
      @vel[2] = -@vel[2]/2

    @hits > 0 and @health > 0

class World
  new: (@game, map="maps.first") =>
    @viewport = EffectViewport scale: 2
    sx, sy = 0, 0

    @entities = DrawList!
    @seqs = DrawList!
    @particles = DrawList!

    @map = TileMap.from_tiled map, {
      map_properties: (data) ->
        @next_level = data.next_level

      object: (o) ->
        switch o.name
          when "spawn"
            sx = o.x
            sy = o.y
          when "door"
            @door = DoorBox o.x, o.y,
              assert(o.properties.to, "door needs need to")
            @entities\add @door
          when "human"
            @entities\add Human o.x, o.y
          when "enemy"
            @entities\add Enemy o.x, o.y
    }


    @player = Player sx, sy

    @entities\add @player

    @hud = Hud @
    @collide = UniformGrid!

  on_show: =>
    @game\on_new_round!
    @game\prepare_player @player

  on_key: (key) =>
    if key == " "
      @player\scare @

    if key == "return"
      return unless @door.touching > 0

      unless @try_enter_door!
        sfx\play "buzz"
        print "you need key"

  try_enter_door: (door=@door)=>
    key, i = door\can_enter @game
    if key
      table.remove @game.inventory, i
      dispatcher\replace World @game, door.to

  draw: =>
    @viewport\center_on @player if @player.alive
    @viewport\apply!
    @map\draw @viewport

    @entities\draw!
    @hud\draw!

    @particles\draw!
    @viewport\pop!

    g.print love.timer.getFPS!, 10, 10

  update: (dt) =>
    @viewport\update dt
    @hud\update dt, @
    @particles\update dt
    @seqs\update dt
    @entities\update dt, @

    @collide\clear!

    for e in *@entities
      continue unless e.w -- probably a rect
      @collide\add e

    for e in *@entities
      continue unless e.on_hit
      for touching in *@collide\get_touching e
        e\on_hit touching, @

    -- check if player is done
    if not @player.alive and not @finish_seq
      @kill_player!

  kill_player: =>
    @finish_seq = true
    @player\on_die @, ->
      @seqs\add Sequence\after 0.5, ->
        @game\show_upgrade!

  collides: (entity) =>
    @map\collides entity

class Game
  money: 0

  new: =>
    @upgrades = {
      hands: 0
      hit: 0
      hp: 0
    }

    @on_new_round!

  on_new_round: =>
    @inventory = {}
    @money_this_round = 0

  prepare_player: (player) =>
    player.hits = Player.hits + @upgrades.hit
    player.health = Player.health + @upgrades.hp

  give_money: (amt) =>
    @money_this_round += amt
    @money += amt

  upgrade_price: (name) =>
    10 + 5 * @upgrades[name]

  show_upgrade: =>
    dispatcher\insert World @
    dispatcher\replace Upgrade @

  on_show: (d) =>
    d\push World @
    -- d\push Upgrade @ -- debug

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  export fonts = {
    default: load_font "images/font1.png", [[ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~!"#$%&'()*+,-./0123456789:;<=>?]]
  }

  g.setFont fonts.default
  g.setBackgroundColor 30,30,30

  export sfx = {
    play: (name) =>
      print "PLAYING SOUND: #{name}"
  }

  export dispatcher = Dispatcher Game!
  dispatcher.default_transition = FadeTransition
  dispatcher\bind love


