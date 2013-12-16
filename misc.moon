
{graphics: g, :keyboard} = love

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

{ :FadeAway }
