
require "lovekit.all"
require "lovekit.reloader"

{graphics: g, :keyboard} = love

import Upgrade from require "upgrade"
import Hud from require "hud"
import Enemy from require "enemy"

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
    if @life <= 0
      @done_fn and @done_fn @
      false
    else
      true


class MoneyEmitter extends Emitter
  class P extends PixelParticle
    size: 4

  count: 10
  make_particle: (x,y) =>
    power = rand 0.8, 1.1
    dx = 5 * rand -0.5, 0.5
    dy = 5 * rand -0.5, 0.5

    P x + dx, y + dy,
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

    world.entities\add MoneyEmitter world, unpack center
    if @has_key
      dir = Vec2d(world.player\center!) - center
      dir = dir\normalized!\random_heading!
      world.entities\add Key @x, @y, dir * 150 * rand(1, 1.3)

  update: (...) =>
    super ...
    true

class Player extends Entity
  is_player: true

  hits: 2
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

    @fit_move @vel[1] * dt, @vel[2] * dt, world
    @hits > 0

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
            @door = o
          when "human"
            @entities\add Human o.x, o.y
          when "enemy"
            @entities\add Enemy o.x, o.y
    }


    @player = Player sx, sy
    @entities\add @player

    -- @entities\add Key sx + 100, sy

    @hud = Hud @
    @collide = UniformGrid!

  on_show: =>
    @game.inventory = {}

  on_key: (key) =>
    if key == " "
      @player\scare @

    if key == "return"
      return unless @door

      pos = Vec2d @player\center!
      door_pos = Vec2d @door.x, @door.y
      door_dist = (pos - door_pos)\len!

      if door_dist < 20
        unless @enter_door!
          print "you need key"

  enter_door: =>
    -- need a key
    key = nil
    for i, item in ipairs @game.inventory
      print item.__class
      if item.__class == Key
        table.remove @game.inventory, i
        key = item
        break

    return false unless key
    dispatcher\replace World @game,
      assert @door.properties.to, "door missing to"

  draw: =>
    @viewport\center_on @player
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
      @finish_seq = true
      @player\on_die @, ->
        @seqs\add Sequence\after 0.2, ->
          @game\show_upgrade!

  collides: (entity) =>
    @map\collides entity

class Game
  money: 0
  upgrades: {
    hands: 0
  }

  new: =>
    @inventory = {}

  show_upgrade: =>
    dispatcher\insert World @
    dispatcher\replace Upgrade @game

  on_show: (d) =>
    d\push World @

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  export fonts = {
    default: load_font "images/font1.png", [[ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~!"#$%&'()*+,-./0123456789:;<=>?]]
  }

  g.setFont fonts.default
  g.setBackgroundColor 30,30,30

  export dispatcher = Dispatcher Game!
  dispatcher.default_transition = FadeTransition
  dispatcher\bind love
