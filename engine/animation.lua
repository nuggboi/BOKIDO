local animation = {}

-- animation library init
local anim8 = require("libs/anim8")

-- animation speeds
local animspds = {
    movespd = 0.09,
    atkspd = 0.02,
    jumpspd = 0.03 -- slower so jump plays properly
}

-- spritesheets
-- player
local playersheet = love.graphics.newImage("assets/player/male_hero_template.png")
local playergrid = anim8.newGrid(128, 128, playersheet:getWidth(), playersheet:getHeight())

-- attacks
local lunge_punchsheet = love.graphics.newImage("assets/player/attacks/lunge_punch.png")
local lunge_punchgrid = anim8.newGrid(128, 128, lunge_punchsheet:getWidth(), lunge_punchsheet:getHeight())

-- movement
local jumpsheet = love.graphics.newImage("assets/player/movement/jump.png")
local jumpgrid = anim8.newGrid(128, 128, jumpsheet:getWidth(), jumpsheet:getHeight())

-- animations
local animations = {
    idle = {
        anim = anim8.newAnimation(playergrid("1-10", 2), animspds.movespd),
        sheet = playersheet
    },
    walk = {
        anim = anim8.newAnimation(playergrid("1-10", 3), animspds.movespd),
        sheet = playersheet
    },
    run = {
        anim = anim8.newAnimation(playergrid("1-10", 4), animspds.movespd),
        sheet = playersheet
    },
    lunge_punch = {
        anim = anim8.newAnimation(lunge_punchgrid("1-43", 1), animspds.atkspd),
        sheet = lunge_punchsheet
    },
    jump = {
        -- false = DO NOT LOOP (important for jump)
        anim = anim8.newAnimation(jumpgrid("1-39", 1), animspds.jumpspd, "pauseAtEnd"),
        sheet = jumpsheet
    }
}

-- init
function animation.load(player)
    player.animation = animations.idle
    player.currentAnimName = "idle" -- track current animation name
end

-- update
function animation.update(player, dt)
    player.animation.anim:update(dt)
end

-- set animation (SAFE: prevents reset spam)
function animation.set(player, name)
    if player.currentAnimName == name then
        return -- already playing, don't reset
    end

    local nextAnim = animations[name]
    if nextAnim then
        player.animation = nextAnim
        player.currentAnimName = name
        player.animation.anim:gotoFrame(1)
    end
end

return animation