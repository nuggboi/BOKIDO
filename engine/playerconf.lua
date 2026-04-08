local playerconf = {}
function playerconf.load()
    --player config
    player = {}
    player.x = 250
    player.y = -250
    player.walkspeed = 1
    player.runspeed = 3

    --flip stuffx
    player.flipped = false
    player.scaleX = 3
    player.targetscaleX = 3
    player.flipspeed = 1.0 --flip speed
    player.speedmult = 150

    --jump globals
    player.cWasDown = false
    player.isJumping = false
    player.jumpsRemaining = 1

    --player collider
    player.collider = world:newCollider("Rectangle", { player.x, player.y, 40, 96 })
    player.collider:setType("dynamic")
    player.collider:setPosition(player.x, player.y)
    player.collider:setFriction(0.5)
    player.collider:setFixedRotation(true) --prevents rotation
end
return playerconf