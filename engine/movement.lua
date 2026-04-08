local movement = {}

function movement.update(player, input, animation, camera, dt, sfx)
    -- velocity
    local vx, vy = player.collider:getLinearVelocity()

    -- ATTACK (press, not hold)
    if input.state.space and not player.spaceWasDown and not player.isAttacking then
        player.isAttacking = true
        player.attackTimer = 0.7
    end
    player.spaceWasDown = input.state.space

    -- state variables
    local walking = false
    local running = false
    local grounded = false

    -- GROUND CHECK
    for _, contact in ipairs(world:getContacts(player.collider)) do
        if contact:isTouching() then
            local f1, f2 = contact:getFixtures()
            local other = (f1 == player.collider.fixture) and f2:getUserData() or f1:getUserData()
            if other == platform.collider then
                grounded = true
                break
            end
        end
    end

    -- MOVE RIGHT
    if input.state.d then
        walking = true
        if input.state.shiftDown then
            vx = player.runspeed * player.speedmult
            running = true
        else
            vx = player.walkspeed * player.speedmult
        end
        player.flipped = false
        player.targetscaleX = 3

    -- MOVE LEFT
    elseif input.state.a then
        walking = true
        if input.state.shiftDown then
            vx = -player.runspeed * player.speedmult
            running = true
        else
            vx = -player.walkspeed * player.speedmult
        end
        player.flipped = true
        player.targetscaleX = -3

    else
        vx = 0
    end

    -- JUMP (trigger ONCE)
    if input.state.c and not player.cWasDown then
        if grounded then
            local jumpForce = -600
            player.collider:setLinearVelocity(vx, jumpForce)
            animation.set(player, "jump") -- ✅ trigger once here
        end
    end
    player.cWasDown = input.state.c

    -- ATTACK TIMER
    if player.isAttacking then
        player.attackTimer = player.attackTimer - dt
        if player.attackTimer <= 0 then
            player.isAttacking = false
        end
    end

    -- ANIMATION STATE MACHINE (CLEAN PRIORITY)
    if player.isAttacking then
        animation.set(player, "lunge_punch")

    elseif not grounded then
        -- in air (jump/fall)
        animation.set(player, "jump")

    elseif running then
        animation.set(player, "run")

    elseif walking then
        animation.set(player, "walk")

    else
        animation.set(player, "idle")
    end

    -- smooth flip
    if player.scaleX < player.targetscaleX then
        player.scaleX = math.min(player.scaleX + player.flipspeed, player.targetscaleX)
    elseif player.scaleX > player.targetscaleX then
        player.scaleX = math.max(player.scaleX - player.flipspeed, player.targetscaleX)
    end

    -- apply velocity (preserve gravity)
    local _, currentVy = player.collider:getLinearVelocity()
    player.collider:setLinearVelocity(vx, currentVy)

    -- sync position
    player.x, player.y = player.collider:getPosition()

    -- camera follow
    local targetX = player.x - love.graphics.getWidth()/2
    local targetY = player.y - love.graphics.getHeight()/2
    camera.x = camera.x + (targetX - camera.x) * dt * camera.speed
    camera.y = camera.y + (targetY - camera.y) * dt * camera.speed
end

return movement