-- engine/enemy.lua
local enemy = {}

local anim8 = require("libs/anim8")
local sheet = love.graphics.newImage("assets/enemy/enemy_sheet.png")
local grid = anim8.newGrid(128, 128, sheet:getWidth(), sheet:getHeight())

local animspds = {
    movespd = 0.09,
    atkspd = 0.02
}

local defaultAnimConfig = {
    idle = { frames = "1-10", row = 1, speed = animspds.movespd },
    walk = { frames = "1-10", row = 2, speed = animspds.movespd },
    attack = { frames = "1-24", row = 3, speed = animspds.atkspd },
    death = { frames = "1-20", row = 4, speed = animspds.atkspd, mode = "pauseAtEnd" }
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
    e.scaleX = opts.scaleX or 3
    e.targetscaleX = e.scaleX
    e.flipped = false

    e.speed = opts.speed or 1
    e.runSpeed = opts.runSpeed or 3
    e.speedMult = opts.speedMult or 150
    e.flipspeed = opts.flipspeed or 2

    e.health = opts.health or 50
    e.invulnTimer = 0

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

    -- create collider (call this after world exists)
    e.collider = world:newCollider("Rectangle", { e.x, e.y, 40, 96 })
    e.collider:setType("dynamic")
    e.collider:setFriction(0.5)
    e.collider:setFixedRotation(true)

    -- animations (instance-specific so animations can run independently)
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
        if self.invulnTimer and self.invulnTimer > 0 then return end
        self.health = self.health - amount
        self.invulnTimer = 0.3
        if source and source.x and self.collider and self.collider.setLinearVelocity then
            local dir = (self.x < source.x) and -1 or 1
            local vx, vy = self.collider:getLinearVelocity()
            self.collider:setLinearVelocity(200 * dir, vy)
        end
        if self.health <= 0 then
            self.isDead = true
            self:die()
        end
    end

    function e:die()
        self:setAnimation("death")
        if self.collider and self.collider.destroy then
            self.collider:destroy()
            self.collider = nil
        end
    end

    function e:update(dt)
        if self.isDead then
            if self.animation and self.animation.anim then
                self.animation.anim:update(dt)
            end
            return
        end

        if self.invulnTimer and self.invulnTimer > 0 then
            self.invulnTimer = self.invulnTimer - dt
        end

        local targetVx = 0
        local currentVy = 0
        if self.collider and self.collider.getLinearVelocity then
            local _vx, _vy = self.collider:getLinearVelocity()
            currentVy = _vy
        end

        local chasing = false
        if player and player.x then
            local dx = player.x - self.x
            local dist = math.abs(dx)
            if dist <= self.aggroRange then
                chasing = true
                local dir = dx > 0 and 1 or -1
                self.flipped = (dir < 0)
                self.targetscaleX = self.flipped and -math.abs(self.scaleX) or math.abs(self.scaleX)
                targetVx = dir * self.runSpeed * self.speedMult

                if dist <= self.attackRange and not self.isAttacking then
                    self.isAttacking = true
                    self.attackTimer = opts.attackDuration or 0.7
                    self.hitboxDelay = opts.hitboxDelay or 0.35
                    self.hitboxSpawned = false
                    targetVx = 0
                    if self.collider and self.collider.setLinearVelocity then
                        self.collider:setLinearVelocity(0, currentVy)
                    end
                end
            end
        end

        if not chasing then
            if (self.patrolDir == 1 and self.x >= self.patrolMaxX) or (self.patrolDir == -1 and self.x <= self.patrolMinX) then
                self.patrolDir = -self.patrolDir
            end
            self.flipped = (self.patrolDir < 0)
            self.targetscaleX = self.flipped and -math.abs(self.scaleX) or math.abs(self.scaleX)
            targetVx = self.patrolDir * self.speed * self.speedMult
        end

        if self.isAttacking then
            self.attackTimer = self.attackTimer - dt
            if self.hitboxDelay and not self.hitboxSpawned then
                self.hitboxDelay = self.hitboxDelay - dt
                if self.hitboxDelay <= 0 then
                    local offsetX = 20
                    local offsetY = -17
                    local w = 50
                    local h = 30
                    local atkX = getAttackX(self.x, offsetX, w, self.flipped)
                    combat.spawnHitbox(atkX, self.y + offsetY, w, h, self.damage, 0.15, self)
                    self.hitboxSpawned = true
                end
            end
            if self.attackTimer <= 0 then
                self.isAttacking = false
                self.hitboxSpawned = false
            end
        end

        if self.collider and self.collider.setLinearVelocity then
            self.collider:setLinearVelocity(targetVx, currentVy)
        end

        if self.collider and self.collider.getPosition then
            self.x, self.y = self.collider:getPosition()
        end

        if self.isAttacking then
            self:setAnimation("attack")
        elseif math.abs(targetVx) > 1 then
            self:setAnimation("walk")
        else
            self:setAnimation("idle")
        end

        if self.animation and self.animation.anim then
            self.animation.anim:update(dt)
        end

        if not self.isAttacking then
            if self.scaleX < self.targetscaleX then
                self.scaleX = math.min(self.scaleX + self.flipspeed, self.targetscaleX)
            elseif self.scaleX > self.targetscaleX then
                self.scaleX = math.max(self.scaleX - self.flipspeed, self.targetscaleX)
            end
        end
    end

    function e:draw(debug)
        if self.animation and self.animation.anim and self.animation.sheet then
            self.animation.anim:draw(self.animation.sheet, self.x, self.y, 0, self.scaleX, 3, 64, 64)
        end
        if debug and self.hurtbox then
            love.graphics.setColor(0, 1, 0, 0.4)
            love.graphics.rectangle("fill", self.x + self.hurtbox.offsetX, self.y + self.hurtbox.offsetY, self.hurtbox.w, self.hurtbox.h)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    return e
end

return enemy