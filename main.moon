
require "lovekit.all"

{graphics: g, :keyboard} = love

class Enemy extends Entity
  alive: true
  w: 10
  h: 10

  draw: =>
    super {255,100,100}

  update: (...) =>
    super
    true

class Player extends Entity
  speed: 100

  update: (dt, world) =>
    @velocity = movement_vector! * @speed
    super dt, world
    true

class Game
  new: =>
    @viewport = Viewport scale: 2
    @entities = DrawList!
    @player = Player 10, 10

    @entities\add @player
    @entities\add Enemy 100, 100

  draw: =>
    @viewport\apply!
    g.print "hello world", 10, 10

    @entities\draw!

    @viewport\pop!

  update: (dt) =>
    @entities\update dt, @

  collides: =>
    false

love.load = ->
  export dispatcher = Dispatcher Game!
  dispatcher\bind love
