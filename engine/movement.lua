local movement = {}

function movement.update(player, input, animation, camera, dt, sfx)
    -- velocity
    local vx, vy = player.collider:getLinearVelocity()

    -- ATTACK (press, not hold)
    if input.state.space and not player.spaceWasDown and not player.isAttacking then
        player.isAttacking = true
        player.attackTimer = 0.7
        sfx.lunge:stop()
        sfx.lunge:play()
    end
    player.spaceWasDown = input.state.space

    --animation state variables
    local walking = false
    local running = false
    local jumping = false

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

    if input.state.c then
        jumping = true
    end
        

    -- animation switch
    if player.isAttacking then
        animation.set(player,"lunge_punch")
    elseif running then
        animation.set(player,"run")
    elseif walking then
        animation.set(player,"walk")
    elseif jumping then
        animation.set(player,"jump")
    else
        animation.set(player,"idle")
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