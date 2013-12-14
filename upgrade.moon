
{graphics: g, :keyboard} = love

class Upgrade
  new: (@game) =>
    @viewport = Viewport scale: 2
    @entities = DrawList!
    @seqs = DrawList!

  update: (dt) =>
    @seqs\update dt
    @entities\update dt, @

  on_key: (key) =>
    if key == "return"
      dispatcher\pop!

  draw: =>
    @viewport\apply!
    g.print "Press enter to continue", 100, 100
    @viewport\pop!

{ :Upgrade }
