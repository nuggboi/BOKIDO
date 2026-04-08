local movement = {}

function movement.update(player, input, animation, camera, dt, sfx)
    -- velocity
    local vx, vy = player.collider:getLinearVelocity()

    -- ATTACK (press, not hold)
    if input.state.space and not player.spaceWasDown and not player.isAttacking then
        player.isAttacking = true
        player.attackTimer = 0.7
        --sfx.lunge:stop()
        --sfx.lunge:play()
    end
    player.spaceWasDown = input.state.space

    --animation state variables
    local walking = false
    local running = false
    local jumping = false
    local grounded = false
    --JUMP RESET
    for _, contact in ipairs(world:getContacts(player.collider)) do
        if contact:isTouching() then
            local f1, f2 = contact:getFixtures()
            local other = (f1 == player.collider.fixture) and f2:getUserData() or f1:getUserData()
            if other == platform.collider then
                grounded = true
                player.jumpsRemaining = 1 -- reset jump
                break
            end
        end
    end

    -- MOVE RIGHT
    if right then
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
    elseif left then
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

    -- Modify your jump input section:
    if input.state.c and not player.cWasDown then
        if grounded then
            -- Apply upward velocity (negative = up in LOVE2D)
            local jumpForce = -600 -- Adjust this value to control jump height
            player.collider:setLinearVelocity(vx, jumpForce)
            player.isJumping = true
        end
        player.cWasDown = true
    elseif not input.state.c then
        player.cWasDown = false
    end
 
    -- animation switch
    if player.isJumping then
        animation.set(player,"jump")
    elseif player.isAttacking then
        animation.set(player,"lunge_punch")
    elseif running then
        animation.set(player,"run")
    elseif walking then
        animation.set(player,"walk")
    else
        animation.set(player,"idle")
    end

    -- Reset jumping when player lands
    if player.isJumping and vy >= 0 and grounded then
        player.isJumping = false
    end

    -- attack timer
    if player.isAttacking then
        player.attackTimer = player.attackTimer - dt
        if player.attackTimer <= 0 then
            player.isAttacking = false
            animation.set(player,"idle")
        end
    end

    -- smooth flip
    if player.scaleX < player.targetscaleX then
        player.scaleX = math.min(player.scaleX + player.flipspeed, player.targetscaleX)
    elseif player.scaleX > player.targetscaleX then
        player.scaleX = math.max(player.scaleX - player.flipspeed, player.targetscaleX)
    end

    -- apply velocity
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