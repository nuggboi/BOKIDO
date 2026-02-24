local animating = {}

--animation library init
local anim8 = require("libraries/anim8")

--animation speeds
local animspds = {
	movespd = 0.09,
	atkspd = 0.02
}

--spritesheets
--player
local playersheet = love.graphics.newImage("assets/player/male_hero_template.png")
local playergrid = anim8.newGrid(128, 128, playersheet:getWidth(), playersheet:getHeight())
--attacks
local lunge_punchsheet = love.graphics.newImage("assets/player/attacks/lunge_punch.png")
local lunge_punchgrid = anim8.newGrid(128, 128, lunge_punchsheet:getWidth(), lunge_punchsheet:getHeight())


--[CURRENT AVAILABLE ANIMATIONS]---------------------------------------------------------------
local animations = {
	idle = {
		anim = anim8.newAnimation(playergrid("1-10",2),animspds.movespd),
		sheet = playersheet
	},
	walk = {
		anim = anim8.newAnimation(playergrid("1-10",3),animspds.movespd),
		sheet = playersheet
	},
	run = {
		anim = anim8.newAnimation(playergrid("1-10",4),animspds.movespd),
		sheet = playersheet
	},
	lunge_punch = {
		anim = anim8.newAnimation(lunge_punchgrid("1-43",1),animspds.atkspd),
		sheet = lunge_punchsheet
	}
}
-----------------------------------------------------------------------------------------------
-- init
function animating.init(player)
	player.animation = animations.idle
end

-- update
function animating.update(player,dt)
	player.animation.anim:update(dt)
end

-- set animation
function animating.set(player,name)
	local nextAnim = animations[name]
	if nextAnim and player.animation ~= nextAnim then
		player.animation = nextAnim
		player.animation.anim:gotoFrame(1)
	end
end

return animating