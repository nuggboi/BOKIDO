local enemy = {}

local anim8 = require("libs/anim8")

local sheet = love.graphics.newImage("assets/enemy/enemy_sheet.png")

--CHANGE THIS IF YOUR SPRITE FRAMES AREN’T 128x128
local FRAME_W = 128
local FRAME_H = 128

local grid = anim8.newGrid(FRAME_W, FRAME_H, sheet:getWidth(), sheet:getHeight())

local animspds = {
    movespd = 0.09,
    atkspd = 0.02
}

local defaultAnimConfig = {
    idle = { frames = "1-10", row = 2, speed = animspds.movespd },
    walk = { frames = "1-10", row = 3, speed = animspds.movespd },
    attack = { frames = "1-48", row = 6, speed = animspds.atkspd },
}

local function buildAnimations(cfg)
    local t = {}
    for name, c in pairs(cfg) do
        local a
        if c.mode then
            a = anim8.newAnimation(grid(c.frames, c.row), c.speed, c.mode)
        else
            a = anim8.newAnimation(grid(c.frames, c.row), c.speed)
        end
        t[name] = { anim = a, sheet = sheet }
    end
    return t
end

local function getAttackX(px, offsetX, width, flipped)
    if flipped then
        return px - offsetX - width
    else
        return px + offsetX
    end
end

function enemy.new(opts)
    opts = opts or {}

    local e = {}

    e.x = opts.x or 600
    e.y = opts.y or 0

    --Use ONE scale value
    e.scale = opts.scale or 3
    e.targetScale = e.scale

    e.flipped = false

    e.speed = opts.speed or 1           -- patrol speed multiplier (1 * speedMult = 150 px/frame)
    e.runSpeed = opts.runSpeed or 3     -- chase/run speed multiplier (3 * speedMult = 450 px/frame)
    e.speedMult = opts.speedMult or 75 -- base velocity multiplier
    e.flipspeed = opts.flipspeed or 2

    e.health = opts.health or 50
    e.invulnTimer = 0

    -- Hurt / flash state
    e.isHurt = false
    e.hurtTimer = 0
    e.hurtDuration = opts.hurtDuration or 0.6
    e.hurtFlashInterval = opts.hurtFlashInterval or 0.06
    e.hurtFlashTimer = 0
    e.hurtFlashOn = false
    e.hurtKnockbackX = opts.hurtKnockbackX or 600
    e.hurtKnockbackY = opts.hurtKnockbackY or -400

    e.hurtbox = opts.hurtbox or { offsetX = -15, offsetY = -36, w = 28, h = 75 }

    e.isAttacking = false
    e.attackTimer = 0
    e.hitboxDelay = 0
    e.hitboxSpawned = false

    e.isDead = false

    e.patrolMinX = opts.patrolMinX or (e.x - 120)
    e.patrolMaxX = opts.patrolMaxX or (e.x + 120)
    e.patrolDir = opts.patrolDir or -1

    e.aggroRange = opts.aggroRange or 250
    e.attackRange = opts.attackRange or 48
    e.damage = opts.damage or 10

    e.collider = world:newCollider("Rectangle", { e.x, e.y, 40, 96 })
    e.collider:setType("dynamic")
    e.collider:setFriction(0.5)
    e.collider:setFixedRotation(true)

    e.animations = buildAnimations(opts.animConfig or defaultAnimConfig)
    e.animation = e.animations.idle
    e.currentAnimName = "idle"

    function e:setAnimation(name)
        if self.currentAnimName == name then return end
        local nextA = self.animations[name]
        if nextA then
            self.animation = nextA
            self.currentAnimName = name
            self.animation.anim:gotoFrame(1)
        end
    end

    function e:takeDamage(amount, source)
        if self.invulnTimer > 0 then return end

        -- apply damage + invulnerability
        self.health = self.health - amount
        self.invulnTimer = self.hurtDuration

        -- set hurt state (freeze animation + flash)
        self.isHurt = true
        self.hurtTimer = self.hurtDuration
        self.hurtFlashTimer = self.hurtFlashInterval
        self.hurtFlashOn = true

        -- pause the current animation so it stays on the current frame
        if self.animation and self.animation.anim and self.animation.anim.pause then
            self.animation.anim:pause()
        end

        -- knockback away from the damage source
        if source and source.x then
            local dir = (self.x < source.x) and -1 or 1
            self.collider:setLinearVelocity(self.hurtKnockbackX * dir, self.hurtKnockbackY)
        end

        if self.health <= 0 then
            self.isDead = true
            self:die()
        end
    end

    function e:die()
        self:setAnimation("death")
        -- make sure death animation plays even if we were paused by hurt
        if self.animation and self.animation.anim and self.animation.anim.resume then
            self.animation.anim:resume()
        end
        if self.collider then
            self.collider:destroy()
            self.collider = nil
        end
    end

    function e:update(dt)
        if self.isDead then
            self.animation.anim:update(dt)
            return
        end

        if self.invulnTimer > 0 then
            self.invulnTimer = self.invulnTimer - dt
        end

        local targetVx = 0
        local _, currentVy = self.collider:getLinearVelocity()

        local chasing = false

        if player and player.x then
            local dx = player.x - self.x
            local dist = math.abs(dx)

            if dist <= self.aggroRange then
                chasing = true
                local dir = dx > 0 and 1 or -1

                self.flipped = (dir < 0)
                targetVx = dir * self.runSpeed * self.speedMult

                if dist <= self.attackRange and not self.isAttacking then
                    self.isAttacking = true
                    self.attackTimer = opts.attackDuration or 0.7
                    self.hitboxDelay = opts.hitboxDelay or 0.35
                    self.hitboxSpawned = false
                    targetVx = 0
                end
            end
        end

        if not chasing then
            if (self.patrolDir == 1 and self.x >= self.patrolMaxX) or
               (self.patrolDir == -1 and self.x <= self.patrolMinX) then
                self.patrolDir = -self.patrolDir
            end

            self.flipped = (self.patrolDir < 0)
            targetVx = self.patrolDir * self.speed * self.speedMult
        end

        if self.isAttacking then
            self.attackTimer = self.attackTimer - dt

            if self.hitboxDelay and not self.hitboxSpawned then
                self.hitboxDelay = self.hitboxDelay - dt
                if self.hitboxDelay <= 0 then
                    local atkX = getAttackX(self.x, 20, 50, self.flipped)
                    combat.spawnHitbox(atkX, self.y - 17, 50, 30, self.damage, 0.15, self)
                    self.hitboxSpawned = true
                end
            end

            if self.attackTimer <= 0 then
                self.isAttacking = false
                self.hitboxSpawned = false
            end
        end

        -- don't override knockback velocity while hurt
        if not self.isHurt then
            self.collider:setLinearVelocity(targetVx, currentVy)
        end

        self.x, self.y = self.collider:getPosition()

        -- only change animations when NOT hurt (we want to freeze the current frame)
        if not self.isHurt then
            if self.isAttacking then
                self:setAnimation("attack")
            elseif math.abs(targetVx) > 1 then
                self:setAnimation("walk")
            else
                self:setAnimation("idle")
            end
        end

        -- handle hurt timers and flash toggling
        if self.isHurt then
            self.hurtTimer = self.hurtTimer - dt
            self.hurtFlashTimer = self.hurtFlashTimer - dt
            if self.hurtFlashTimer <= 0 then
                self.hurtFlashOn = not self.hurtFlashOn
                self.hurtFlashTimer = self.hurtFlashInterval
            end
            if self.hurtTimer <= 0 then
                self.isHurt = false
                self.hurtFlashOn = false
                if self.animation and self.animation.anim and self.animation.anim.resume then
                    self.animation.anim:resume()
                end
            end
        end

        -- update animation only when not hurt (paused during hurt)
        if self.animation and self.animation.anim and not self.isHurt then
            self.animation.anim:update(dt)
        end
    end

    function e:draw(debug)
        if self.animation then
            --Proper flipping WITHOUT breaking width
            local sx = self.flipped and -self.scale or self.scale

            self.animation.anim:draw(
                self.animation.sheet,
                self.x,
                self.y,
                0,
                sx,
                self.scale,
                FRAME_W / 2,
                FRAME_H / 2
            )

            -- white flash overlay while hurt (additive draw of same frame)
            if self.isHurt and self.hurtFlashOn then
                love.graphics.setBlendMode("add")
                love.graphics.setColor(1, 1, 1, 0.85)
                self.animation.anim:draw(
                    self.animation.sheet,
                    self.x,
                    self.y,
                    0,
                    sx,
                    self.scale,
                    FRAME_W / 2,
                    FRAME_H / 2
                )
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(1, 1, 1, 1)
            end
        end

        if debug then
            love.graphics.setColor(0, 1, 0, 0.4)
            love.graphics.rectangle("fill",
                self.x + self.hurtbox.offsetX,
                self.y + self.hurtbox.offsetY,
                self.hurtbox.w,
                self.hurtbox.h
            )
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    return e
end

return enemy