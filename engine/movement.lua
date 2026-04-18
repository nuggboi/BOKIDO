local movement = {}

function movement.update(player, input, animation, camera, dt, sfx)
    -- velocity
    local vx, vy = player.collider:getLinearVelocity()

    -- ATTACK (press, not hold) -> C
    if input.state.c and not player.cWasDown and not player.isAttacking then
        player.isAttacking = true
        player.attackTimer = 0.7

        --hitbox stuff
        player.attackStarted = true
        player.hitboxDelay = 0.55

        -- HARD STOP when attack begins
        player.collider:setLinearVelocity(0, vy)
    end
    player.cWasDown = input.state.c

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

    --  MOVEMENT LOCK DURING ATTACK
    if not player.isAttacking then

        --  ANALOG MOVEMENT
        local moveX = input.state.moveX or 0

        -- deadzone
        if math.abs(moveX) < 0.1 then
            moveX = 0
        end

        if moveX ~= 0 then
            walking = true

            -- how far stick is tilted (0 → 1)
            local inputStrength = math.abs(moveX)

            -- smooth curve (feels better)
            inputStrength = inputStrength * inputStrength

            local speed = player.walkspeed
            if input.state.shiftDown then
                speed = player.runspeed
                running = true
            end

            vx = speed * inputStrength * (moveX > 0 and 1 or -1) * player.speedmult

            -- direction
            if moveX > 0 then
                player.flipped = false
                player.targetscaleX = 3
            else
                player.flipped = true
                player.targetscaleX = -3
            end
        else
            vx = 0
        end

    else
        --FORCE NO MOVEMENT DURING ATTACK
        vx = 0
    end

    -- JUMP (trigger ONCE) -> SPACE
    if input.state.space and not player.spaceWasDown then
        if grounded and not player.isAttacking then
            local jumpForce = -600
            player.collider:setLinearVelocity(vx, jumpForce)
            animation.set(player, "jump")
        end
    end
    player.spaceWasDown = input.state.space

    -- ATTACK TIMER
    if player.isAttacking then
        player.attackTimer = player.attackTimer - dt
        if player.attackTimer <= 0 then
            player.isAttacking = false
        end
    end

    -- ANIMATION STATE MACHINE
    if player.isAttacking then
        animation.set(player, "lunge_punch")

    elseif not grounded then
        animation.set(player, "jump")

    elseif running then
        animation.set(player, "run")

    elseif walking then
        animation.set(player, "walk")

    else
        animation.set(player, "idle")
    end

    -- smooth flip (disabled during attack)
    if not player.isAttacking then
        if player.scaleX < player.targetscaleX then
            player.scaleX = math.min(player.scaleX + player.flipspeed, player.targetscaleX)
        elseif player.scaleX > player.targetscaleX then
            player.scaleX = math.max(player.scaleX - player.flipspeed, player.targetscaleX)
        end
    end

    -- FINAL velocity apply (preserve gravity)
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