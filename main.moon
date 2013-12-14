
require "lovekit.all"

{graphics: g, :keyboard} = love

class ScareParticle extends Box
  life: 1
  used: false -- has hit something

  new: (@player, ...)=>
    super ...

  draw: =>
    super {255,255, 0}

  update: (dt, world) =>
    @life -= dt
    @life > 0

  on_hit: (entity) =>
    return if @used
    return unless entity.is_human

    print "Hitting human! give me ghost bucks"
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
  hits: 0
  speed: 100

  new: (x,y) =>
    @seqs = DrawList!
    super x,y

  scare: (world) =>
    return if @scare_cooloff

    @scare_cooloff = true

    print "scare someone"
    radius = ScareParticle @, @scale(2, 2, true)\unpack!
    world.entities\add radius

    @seqs\add Sequence\after 1, ->
      @scare_cooloff = false

  update: (dt, world) =>
    @seqs\update dt
    @velocity = movement_vector! * @speed
    super dt, world
    true

class Game
  money: 0

  new: =>
    @viewport = Viewport scale: 2
    @entities = DrawList!
    @player = Player 10, 50

    @entities\add @player
    @entities\add Enemy 100, 100
    @entities\add Human 200, 100
    
    @collide = UniformGrid!

  on_key: (key) =>
    if key == " "
      @player\scare @

  draw: =>
    @viewport\apply!
    g.print "Hits: 0 - Ghost Bucks: #{@money}", 10, 10

    @entities\draw!

    @viewport\pop!

  update: (dt) =>
    @entities\update dt, @
    @collide\clear!

    for e in *@entities
      @collide\add e

    for e in *@entities
      continue unless e.on_hit
      for touching in *@collide\get_touching e
        e\on_hit touching

  collides: =>
    false

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
