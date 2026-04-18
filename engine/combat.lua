local combat = {}

-- active hitboxes
combat.hitboxes = {}

--------------------------------------------------
-- Spawn a hitbox
--------------------------------------------------
function combat.spawnHitbox(x, y, w, h, damage, duration, owner)
    table.insert(combat.hitboxes, {
        x = x,
        y = y,
        w = w,
        h = h,
        damage = damage,
        timer = duration,
        owner = owner,
        hitTargets = {}
    })
end

--------------------------------------------------
-- Update hitboxes (lifetime)
--------------------------------------------------
function combat.update(dt)
    for i = #combat.hitboxes, 1, -1 do
        local hb = combat.hitboxes[i]
        hb.timer = hb.timer - dt

        if hb.timer <= 0 then
            table.remove(combat.hitboxes, i)
        end
    end
end

--------------------------------------------------
-- Helper: correct flipped positioning
--------------------------------------------------
local function getAttackX(playerX, offsetX, width, flipped)
    if flipped then
        return playerX - offsetX - width
    else
        return playerX + offsetX
    end
end

--------------------------------------------------
-- PLAYER ATTACK HANDLING
--------------------------------------------------
function combat.handlePlayerAttack(player, dt)
    if not player or not dt then return end

    if player.isAttacking then

        -- countdown delay
        if player.hitboxDelay and not player.hitboxSpawned then
            player.hitboxDelay = player.hitboxDelay - dt

            if player.hitboxDelay <= 0 then
                local offsetX = 20
                local offsetY = -17
                local w = 50
                local h = 30

                local x = getAttackX(player.x, offsetX, w, player.flipped)

                combat.spawnHitbox(
                    x,
                    player.y + offsetY,
                    w,
                    h,
                    10,
                    0.15,
                    player
                )

                player.hitboxSpawned = true
            end
        end

    else
        -- reset for next attack
        player.hitboxSpawned = false
    end
end

--------------------------------------------------
-- AABB collision check
--------------------------------------------------
local function checkCollision(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
end

--------------------------------------------------
-- Handle combat (apply damage)
--------------------------------------------------
function combat.handle(entities)
    if not entities then return end

    for _, hb in ipairs(combat.hitboxes) do
        for _, target in ipairs(entities) do

            if target ~= hb.owner then

                -- skip dead targets
                if target.health and target.health <= 0 then
                    goto continue
                end

                -- optional i-frames
                if target.invulnTimer and target.invulnTimer > 0 then
                    goto continue
                end

                -- build hurtbox
                local hurtbox = {
                    x = target.x + target.hurtbox.offsetX,
                    y = target.y + target.hurtbox.offsetY,
                    w = target.hurtbox.w,
                    h = target.hurtbox.h
                }

                if checkCollision(hb, hurtbox) then
                    if not hb.hitTargets[target] then
                        target.health = target.health - hb.damage
                        hb.hitTargets[target] = true

                        -- apply i-frames
                        target.invulnTimer = 0.3

                        -- optional knockback
                        if target.vx then
                            local dir = (target.x < hb.x) and -1 or 1
                            target.vx = 200 * dir
                        end
                    end
                end
            end

            ::continue::
        end
    end
end

--------------------------------------------------
-- Update entity timers (like i-frames)
--------------------------------------------------
function combat.updateEntities(entities, dt)
    if not entities then return end

    for _, e in ipairs(entities) do
        if e.invulnTimer and e.invulnTimer > 0 then
            e.invulnTimer = e.invulnTimer - dt
        end
    end
end

--------------------------------------------------
-- Debug draw
--------------------------------------------------
function combat.draw(entities)
    -- hitboxes (red)
    for _, hb in ipairs(combat.hitboxes) do
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", hb.x, hb.y, hb.w, hb.h)
    end

    -- hurtboxes (green)
    if entities then
        for _, e in ipairs(entities) do
            if e.hurtbox then
                love.graphics.setColor(0, 1, 0, 0.5)
                love.graphics.rectangle(
                    "fill",
                    e.x + e.hurtbox.offsetX,
                    e.y + e.hurtbox.offsetY,
                    e.hurtbox.w,
                    e.hurtbox.h
                )
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
end

return combat