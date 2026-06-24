local playerconf = {}
function playerconf.load()
    -- player config
    player = {}
    player.x = 250
    player.y = -250
    player.walkspeed = 1
    player.runspeed = 3

    -- flip stuffx
    player.flipped = false
    player.scaleX = 3
    player.targetscaleX = 3
    player.flipspeed = 2 -- flip speed
    player.speedmult = 150

    -- jump globals
    player.cWasDown = false
    player.spaceWasDown = false
    player.isJumping = false
    player.jumpsRemaining = 1
    -- attack defaults
    player.isAttacking = false
    player.attackTimer = 0
    player.attackStarted = false
    player.hitboxDelay = 0
    player.hitboxSpawned = false
    player.attackType = nil
    player.xWasDown = false

    -- configurable attack hitboxes (change these to tweak offsets/dimensions/damage/duration)
    player.attackHitboxes = {
        punch = {
            offsetX = 20,
            offsetY = -17,
            w = 50,
            h = 30,
            damage = 10,
            duration = 0.15,
            hitboxDelay = 0.55,
            attackTimer = 0.7
        },
        kick = {
            offsetX = 80,
            offsetY = -20,
            w = 55,
            h = 30,
            damage = 15,
            duration = 0.135,
            hitboxDelay = 0.5,
            attackTimer = 0.6
        }
    }

    -- player collider
    player.collider = world:newCollider("Rectangle", {player.x, player.y, 40, 96})
    player.collider:setType("dynamic")
    player.collider:setPosition(player.x, player.y)
    player.collider:setFriction(0.5)
    player.collider:setFixedRotation(true) -- prevents rotation

    -- ensure fixture userData for contact checks
    if player.collider.fixture then
        player.collider.fixture:setUserData(player.collider)
    end

    -- combat
    player.health = 100
    player.invulnTimer = 0

    player.hurtbox = {
        offsetX = -15,
        offsetY = -36,
        w = 28,
        h = 75
    }

end
return playerconf
