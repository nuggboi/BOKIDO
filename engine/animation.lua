local animation = {}

-- animation library init
local anim8 = require("libs/anim8")

-- animation speeds
local animspds = {
    movespd = 0.09,
    atkspd = 0.02,
    jumpspd = 0.03 -- slower so jump plays properly
}

-- spritesheet
local playersheet = love.graphics.newImage("assets/player/player_sheet.png")
local playergrid = anim8.newGrid(128, 128, playersheet:getWidth(), playersheet:getHeight())

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
        anim = anim8.newAnimation(playergrid("1-48", 6), animspds.atkspd),
        sheet = playersheet
    },
    jump = {
        -- false = DO NOT LOOP (important for jump)
        anim = anim8.newAnimation(playergrid("1-39", 5), animspds.jumpspd, "pauseAtEnd"),
        sheet = playersheet
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