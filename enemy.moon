
{graphics: g, :keyboard} = love

class Enemy extends Entity
  is_enemy: true
  health: 1

  w: 10
  h: 10
  speed: 20

  new: (x,y) =>
    super x, y
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
    super {255,100,100}

  update: (dt, @world) =>
    @ai\update dt

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, @world

    if cx
      @vel[1] = -@vel[1]
    if cy
      @vel[2] = -@vel[2]

    true



{ :Enemy }
