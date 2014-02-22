
require "lovekit.all"
-- require "lovekit.reloader"

export VIEWPORT_OPTS = {
  w: 214
  h: 134
  margin: 0
}

{graphics: g, :keyboard} = love

import Upgrade from require "upgrade"
import Hud from require "hud"
import Enemy from require "enemy"
import Title, WinGame from require "screens"
import FadeAway from require "misc"


paused = false
export show_boxes = false

local *

class MessageBox
  padding: 5
  visible: true
  box_color: {0,0,0, 100}

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

    p = @padding

    COLOR\pusha @alpha
    g.push!
    g.translate x, y
    COLOR\push @box_color
    g.rectangle "fill", -p, -p, width + p * 2, height + p * 2
    COLOR\pop!
    g.print @text, 0,0
    g.pop!
    COLOR\pop!

  hide: =>
    return if @hiding or not @visible
    @hiding = true
    @seq = Sequence ->
      tween @, 0.2, { alpha: 0 }
      @hiding = false
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
    if show_boxes
      super {255, 100, 255,100}

  can_enter: (game) =>
    for i, item in ipairs game.inventory
      if item.__class == Key
        return item, i

  on_hit: (entity, world) =>
    if entity.is_player
      unless @message_box
        msg = if @can_enter world.game
          "Press 'C' to enter"
        else
          "You need a key"

        @message_box = MessageBox msg
        world.hud\show_message_box @message_box

      @touching = 2

  update: (dt) =>
    if @touching > 0
      @touching -= 1

    if @touching == 0 and @message_box
      @message_box\hide!
      @message_box = nil

    true

class Key extends Entity
  lazy sprite: -> Spriter "images/tiles.png", 16, 16

  w: 10
  h: 5

  ox: 3
  oy: 3

  on_ground: true
  collectable: false

  new: (x,y, vel) =>
    super x, y
    @vel = vel if vel

  on_hit: (entity, world) =>
    return unless @on_ground
    return if @vel\len! > 10
    return unless entity.is_player

    @on_ground = false
    sfx\play "buy"
    table.insert world.game.inventory, @

  draw: =>
    @sprite\draw "48,192,16,10", @x - @ox, @y - @oy
    if show_boxes
      super {255, 255, 100, 100}

  update: (dt, world) =>
    return false unless @on_ground

    dampen_vector @vel, dt * 200

    cx,cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = -@vel[1]
    if cy
      @vel[2] = -@vel[2]

    true

class BooParticle extends ImageParticle
  lazy sprite: -> Spriter "images/tiles.png", 16, 16
  w: 39
  h: 33
  quad: "38,214,39,33"

class BooEmitter extends Emitter
  count: 3
  speed: 100

  make_particle: (...) =>
    with BooParticle ...
      .vel = Vec2d(0,-1)\random_heading(60) * @speed
      .scale = 0.5
      .accel = Vec2d 0, @speed*2
      .dspin = rand -2,2
      .dscale = rand 1, 1.2

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
  life: 0.5
  used: false -- has hit something

  new: (@player, ...)=>
    super ...

  draw: =>
    if show_boxes
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
  lazy sprite: -> Spriter "images/tiles.png", 16, 16

  is_human: true
  is_scared: false
  has_key: true

  h: 20

  ox: 7
  oy: 30
  touching_player: 0

  new: (x, y, @has_key=true) =>
    @move_center x, y
    @anim = @sprite\seq {"0,192,32,48"}, 0
    @effects = EffectList!

  draw: =>
    @effects\before!
    COLOR\push 100,100,00 if @is_scared
    @anim\draw @x - @ox, @y - @oy
    COLOR\pop! if @is_scared
    @effects\after!

    if show_boxes
      if @is_scared
        super {100,255,255, 100}
      else
        super {100,255,100, 100}

  on_hit: (entity, world) =>
    return if @is_scared

    if entity.is_player
      @touching_player = 2
      unless @message_box
        @message_box = MessageBox "Press 'X' to haunt"
        world.hud\show_message_box @message_box

  on_scare: (world) =>
    sfx\play "steal"
    @is_scared = true
    center = Vec2d @center!
    amt = 10
    @effects\add ShakeEffect 0.5

    world.entities\add MoneyEmitter amt, world, unpack center
    world.game\give_money amt

    if @has_key
      dir = Vec2d(world.player\center!) - center
      dir = dir\normalized!\random_heading!
      x,y = @center!

      world.entities\add Key x, y, dir * 150 * rand(1, 1.3)

  update: (dt) =>
    @effects\update dt

    if @touching_player > 0
      @touching_player -= 1

    if @touching_player == 0 and @message_box
      @message_box\hide!
      @message_box = nil

    true

class Player extends Entity
  lazy sprite: -> Spriter "images/player.png", 32, 45

  is_player: true

  hits: 1
  health: 1

  w: 16
  h: 7

  ox: 8
  oy: 34

  speed: 18
  max_speed: 60

  new: (x,y) =>
    @seqs = DrawList!
    @accel = Vec2d 0, 0
    super x,y

    with @sprite
      @anim = StateAnim "right", {
        left: \seq {0,1,2,3,4,5}, 0.3
        right: \seq {0,1,2,3,4,5}, 0.3, true
      }

  scare: (world) =>
    return if @scare_cooloff
    reutrn unless @hits > 0

    @scare_cooloff = true

    radius = @scale(2, 4, true)
    world.entities\add ScareParticle @, radius\unpack!
    world.particles\add BooEmitter world, radius\center!

    sfx\play "scare"
    @hits -= 1

    @seqs\add Sequence\after 0.3, ->
      @scare_cooloff = false

  on_die: (world, complete) =>
    sfx\play "die"
    world.entities\add FadeAway @, complete

  on_hit: (entity, world) =>
    return if @stunned
    if entity.is_enemy
      @health -= 1
      sfx\play "take_damage"

      if @health <= 0
        world\kill_player!

      @vel = entity\vector_to(@)\normalized! * 150
      world.viewport\shake!
      @stunned = true
      @seqs\add Sequence\after 0.1, ->
        @stunned = false

  draw: =>
    COLOR\pusha 225
    @anim\draw @x - @ox, @y - @oy
    COLOR\pop!

    if show_boxes
      if @stunned
        super {200,200,200,100}
      else
        super {255,255,255, 100}

  update: (dt, world) =>
    @anim\update dt
    @seqs\update dt
    decel = @speed * 10 * dt
    @accel = controller\movement_vector! * @speed

    if @stunned
      decel *= 4
      @accel = Vec2d!

    unless @stunned
      if @accel[1] > 0
        @anim\set_state "right"
      elseif @accel[1] < 0
        @anim\set_state "left"

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

    if cx or cy
      unless @hit_timeout
        sfx\play "hit_wall"
        @hit_timeout = true
        @seqs\add Sequence\after 0.1, ->
          @hit_timeout = false

    @hits > 0 and @health > 0

class World
  new: (@game, map="maps.first", @old_player) =>
    @viewport = EffectViewport VIEWPORT_OPTS
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
            @entities\add Human o.x, o.y, o.properties.has_key
          when "enemy"
            @entities\add Enemy o.x, o.y
    }

    @player = @old_player or Player!
    @player\move_center sx, sy

    @entities\add @player

    @hud = Hud @
    @collide = UniformGrid!


    -- map specific things
    switch map
      when "maps.second"
        msg_box = MessageBox "Haunt red ghost to kill"
        @hud\show_message_box msg_box
        @seqs\add Sequence\after 5, ->
          msg_box\hide!

  on_show: =>
    unless sfx.current_music == "ghost"
      sfx\play_music "ghost"

    @game\on_new_round!
    @game\prepare_player @player, not @old_player

  mousepressed: (x,y) =>
    -- x, y = @viewport\unproject x, y
    -- @particles\add BooEmitter @, x,y

  on_input: =>
    if controller\is_down "scare"
      @player\scare @

    if controller\is_down "open"
      if @door and @door.touching > 0 and @try_enter_door!
        return

      sfx\play "buzz"


    if controller\is_down "pause"
      paused = not paused

  try_enter_door: (door=@door)=>
    key, i = door\can_enter @game
    if key
      table.remove @game.inventory, i
      sfx\play "start_game"
      if door.to == "finish"
        dispatcher\replace WinGame!
      else
        dispatcher\replace World @game, door.to, @player

  draw: =>
    @viewport\center_on @player if @player.alive
    @viewport\apply!
    @map\draw @viewport

    @entities\draw_sorted!
    @hud\draw!

    @particles\draw!
    @viewport\pop!

    -- g.print love.timer.getFPS!, 10, 10

  update: (dt) =>
    return if paused

    @viewport\update dt
    @hud\update dt, @
    @particles\update dt
    @seqs\update dt
    @entities\update dt, @

    @collide\clear!

    for e in *@entities
      continue unless e.alive
      continue unless e.w -- probably a rect
      @collide\add e

    for e in *@entities
      continue unless e.alive
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

_G.Game = class Game
  money: 0

  @new_game_state: =>
    game = Game!
    World game

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

  prepare_player: (player, first_level) =>
    if first_level
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
  g.setBackgroundColor 17,18, 15


  export sfx = Audio "sounds"
  -- sfx.play_music = ->
  sfx\preload {
    "start_game"
    "hit_wall"
    "take_damage"
    "buzz"
    "die"
    "scare"
    "steal"
    "buy"
  }

  export controller = Controller {
    left: "left"
    right: "right"
    up: "up"
    down: "down"

    confirm: { "x",  "return", joystick: 1}
    cancel: { "c", "escape", joystick: 2 }
    scare: { "x", " ", joystick: 1 }

    open: { "c", "return", joystick: 2 }
    pause: { "p", joystick: 8 }

    upgrade_one: {"1", joystick: 5}
    upgrade_two: {"1", joystick: 6}
  }, "auto"

  sfx.play_music = =>

  export dispatcher = Dispatcher Title!
  dispatcher.default_transition = FadeTransition
  dispatcher\bind love

