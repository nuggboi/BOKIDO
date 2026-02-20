function love.load() -- load all variables, colliders, animations, etc
	--window config
	love.window.setMode(1200, 800)
	love.window.setTitle("Fighting Game")

	--pixel perfect
	love.graphics.setDefaultFilter("nearest", "nearest")

	--library inits
	local anim8 = require("libraries/anim8")
	local moonshine = require("libraries/moonshine")
	local bf = require("libraries/breezefield-master")

	--other file inits
	parallax = require("parallax")

	--physics world init
	world = bf.newWorld(0, 1200) --gravity
	--register contact callbacks
	world:setCallbacks(beginContact, endContact)

	--shader config
	effect = moonshine(moonshine.effects.scanlines) -- init shader
	effect.scanlines.opacity = 0.25 -- how visible the scanlines are (0-1)
	effect.scanlines.thickness = 1.2 -- width of each scanline

	--player config
	player = {}
	player.x = 250
	player.y = -250
	player.walkspeed = 1
	player.runspeed = 3
	player.jumpforce = 400

	--animation tables
	lunge_punch = {}
	--flip stuffx
	player.flipped = false
	player.scaleX = 3
	player.targetscaleX = 3
	player.flipspeed = 0.8
	player.speedmult = 150
	--player collider
	player.collider = world:newCollider("Rectangle", { player.x, player.y, 40, 96 })
	player.collider:setType("dynamic")
	player.collider:setPosition(player.x, player.y)
	player.collider:setFriction(0.5)
	player.collider:setFixedRotation(true) --prevents rotation

	--spritesheet config
	--player
	player.sheet = love.graphics.newImage("assets/player/male_hero_template.png")
	player.grid = anim8.newGrid(128, 128, player.sheet:getWidth(), player.sheet:getHeight())
	--attacks
	lunge_punch.sheet = love.graphics.newImage("assets/player/attacks/lunge_punch.png")
	lunge_punch.grid = anim8.newGrid(128, 128, lunge_punch.sheet:getWidth(), lunge_punch.sheet:getHeight())

	--animation speeds
	animspds = {}
	animspds.movespd = 0.09
	animspds.atkspd = 0.02
	--animations
	animations = {}
	animations.idle = {
		anim = anim8.newAnimation(player.grid("1-10", 2), animspds.movespd), --speed
		sheet = player.sheet,
	}
	animations.walk = {
		anim = anim8.newAnimation(player.grid("1-10", 3), animspds.movespd),
		sheet = player.sheet,
	}
	animations.run = {
		anim = anim8.newAnimation(player.grid("1-10", 4), animspds.movespd),
		sheet = player.sheet,
	}
	animations.lunge_punch = {
		anim = anim8.newAnimation(lunge_punch.grid("1-43", 1), animspds.atkspd),
		sheet = lunge_punch.sheet,
	}
	player.animation = animations.idle

	--camera config
	camera = { x = 0, y = 0, speed = 5 } --speed = how fast it catches up

	--PARALLAX CONFIG
	background = {
		love.graphics.newImage("assets/background/1.png"),
		love.graphics.newImage("assets/background/2.png"),
		love.graphics.newImage("assets/background/3.png"),
		love.graphics.newImage("assets/background/4.png"),
		love.graphics.newImage("assets/background/5.png"),
		love.graphics.newImage("assets/background/6.png"),
	}

	--platform config
	platform = {}
	platform.sprite = love.graphics.newImage("assets/platforms/placeholderplatform.png")
	platform.x = -40
	platform.y = 50
	platform.w = platform.sprite:getWidth() * 5
	platform.h = platform.sprite:getHeight() * 4
	--platform collider
	platform.collider = world:newCollider("Rectangle", { 520, 62, platform.w, platform.h })
	platform.collider:setType("static")

	--sfx init
	lungepunchsfx = love.audio.newSource("audio/sfx/atkx/lungepunch/lungepunch1.wav", "static")
end

function setAnimation(name)
	local nextAnim = animations[name]
	if player.animation ~= nextAnim then
		player.animation = nextAnim
		player.animation.anim:gotoFrame(1)
	end
end

function love.update(dt) -- updates physics, movement, animation
	--physics update
	world:update(dt)

	--velocity
	local vx, vy = player.collider:getLinearVelocity()

	--check for shift
	local shiftDown = love.keyboard.isDown("lshift")

	--nokeys variable
	local a = love.keyboard.isDown("a")
	local d = love.keyboard.isDown("d")
	local s = love.keyboard.isDown("s")
	local w = love.keyboard.isDown("w")
	local space = love.keyboard.isDown("space")
	local nokeys = not (a or d or s or w or shiftDown)

	--attacks
	-- LUNGE PUNCH (press, not hold)
	if space and not spaceWasDown and not player.isAttacking then
		player.isAttacking = true
		player.attackTimer = 0.7
		lungepunchsfx:stop()
		lungepunchsfx:play()
	end
	spaceWasDown = space

	--MOVE RIGHT
	if d then
		walking = true --walking anim
		if shiftDown then --shift check
			vx = player.runspeed * player.speedmult --move player collider
			running = true --running anim
		else
			vx = player.walkspeed * player.speedmult --move player collider
		end
		player.flipped = false --flip stuff
		player.targetscaleX = 3 --flip stuff
	elseif nokeys then
		walking = false --stop anims except idle
		running = false --stop anims except idle
		vx = 0 --set velocity to 0
		-- DO NOT zero vy here! otherwise it cancels the jump impulse
	end

	--MOVE LEFT
	if a then
		walking = true --walking anim
		if shiftDown then --shift check
			vx = -player.runspeed * player.speedmult --move player collider
			running = true --running anim
		else
			vx = -player.walkspeed * player.speedmult --move player collider
		end
		player.flipped = true --flip stuff
		player.targetscaleX = -3 --flip stuff
	elseif nokeys then
		walking = false --stop anims except idle
		running = false --stop anims except idle
		vx = 0
	end

	--LUNGE PUNCH
	if space and not lungepunching then
		lungepunching = true
		attacktimer = attackduration
	elseif nokeys then
		walking = false
		running = false
		vx = 0
	end

	--animation switch
	if player.isAttacking then
		setAnimation("lunge_punch")
	elseif running then
		setAnimation("run")
	elseif walking then
		setAnimation("walk")
	else
		setAnimation("idle")
	end

	--attack stop
	if player.isAttacking then
		player.attackTimer = player.attackTimer - dt
		if player.attackTimer <= 0 then
			player.isAttacking = false
			setAnimation("idle")
		end
	end

	--smooth flip
	if player.scaleX < player.targetscaleX then
		player.scaleX = math.min(player.scaleX + player.flipspeed, player.targetscaleX)
	elseif player.scaleX > player.targetscaleX then
		player.scaleX = math.max(player.scaleX - player.flipspeed, player.targetscaleX)
	end

	--update player animation
	player.animation.anim:update(dt)

	--APPLY VELOCITY TO COLLIDER
	local _, currentVy = player.collider:getLinearVelocity()
	player.collider:setLinearVelocity(vx, currentVy)

	--UPDATE PLAYER POSITION TO FOLLOW COLLIDER
	player.x, player.y = player.collider:getPosition()

	--camera follow
	local targetX = player.x - love.graphics.getWidth() / 2
	local targetY = player.y - love.graphics.getHeight() / 2
	camera.x = camera.x + (targetX - camera.x) * dt * camera.speed
	camera.y = camera.y + (targetY - camera.y) * dt * camera.speed
end

function love.draw()
	--SHADER
	effect(function()
		parallax.draw(background, camera)

		-- Apply camera transform for world objects
		love.graphics.push()
		love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))

		--platform
		love.graphics.draw(platform.sprite, platform.x, platform.y, 0, 5, 4)

		--player draw
		player.animation.anim:draw(player.animation.sheet, player.x, player.y, 0, player.scaleX, 3, 64, 64)

		--collision debug
		world:draw()

		--update
		love.graphics.pop()
	end)
end