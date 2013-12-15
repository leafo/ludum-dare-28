
{graphics: g, :keyboard} = love

class Enemy extends Entity
  lazy sprite: -> Spriter "images/enemy.png", 32, 52

  w: 16
  h: 7

  is_enemy: true
  health: 1

  ox: 9
  oy: 40

  speed: 20

  new: (x,y) =>
    super x, y
    with @sprite
      @anim = StateAnim "left", {
        left: \seq {0,1,2,3,4,5}, 0.3
        right: \seq {0,1,2,3,4,5}, 0.3, true
      }

    @ai = Sequence ->
      dir = switch pick_dist {
        rand: 2
        player: 4
        wait: 1
      }
        when "rand"
          Vec2d.from_radians rand 0, 2 * math.pi
        when "player"
          towards_player = @vector_to(@world.player)\normalized!
          towards_player\random_heading 30, random_normal!
        when "wait"
          dir = Vec2d!

      @vel = dir * (@speed * rand 1, 1.5)
      wait rand 1,2
      again!

  draw: =>
    @anim\draw @x - @ox, @y - @oy
    super {255,100,100, 100}

  update: (dt, @world) =>
    COLOR\pusha 225
    @ai\update dt
    COLOR\pop!

    if @vel[1] > 0
      @anim\set_state "right"
    elseif @vel[1] < 0
      @anim\set_state "left"

    @anim\update dt

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, @world

    if cx
      @vel[1] = -@vel[1]
    if cy
      @vel[2] = -@vel[2]

    true



{ :Enemy }
