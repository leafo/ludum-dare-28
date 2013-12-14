
require "lovekit.all"
require "lovekit.reloader"

{graphics: g, :keyboard} = love

import Upgrade from require "upgrade"
import Hud from require "hud"

class Key extends Entity
  w: 5
  h: 5
  on_ground: true

  on_hit: (entity, world) =>
    return unless entity.is_player
    @on_ground = false
    table.insert world.game.inventory, @

  draw: =>
    super {255, 255, 100}

  update: =>
    @on_ground

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
    return unless entity.is_human

    print "Hitting human! give me ghost bucks"
    world.entities\add MoneyEmitter world, entity\center!

    @used = true

class Enemy extends Entity
  is_enemy: true

  alive: true
  w: 10
  h: 10

  draw: =>
    super {255,100,100}

  update: (...) =>
    super
    true

class Human extends Entity
  is_human: true

  draw: =>
    super {100,255,100}

  update: (...) =>
    super
    true

class Player extends Entity
  is_player: true

  hits: 1
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

    @seqs\add Sequence\after 1, ->
      @scare_cooloff = false

  on_die: (world, complete) =>
    world.entities\add FadeAway @, complete

  update: (dt, world) =>
    @seqs\update dt
    decel = @speed * 10 * dt
    @accel = movement_vector! * @speed

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
    @viewport = Viewport scale: 2
    sx, sy = 0, 0

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
    }

    @entities = DrawList!
    @seqs = DrawList!
    @particles = DrawList!

    @player = Player sx, sy

    @entities\add @player
    @entities\add Enemy 100, 100
    @entities\add Human 200, 100

    @entities\add Key sx + 100, sy

    @hud = Hud @

    @collide = UniformGrid!

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
          dispatcher\pop!

  collides: (entity) =>
    @map\collides entity

class Game
  money: 0
  upgrades: {
    hands: 0
  }

  new: =>
    @inventory = {}

  on_show: (d) =>
    if @world
      @world = nil
      d\push Upgrade @
    else
      print "pushing new world"
      @world = World @
      d\push @world

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
  dispatcher\bind love