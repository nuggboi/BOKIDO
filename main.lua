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
	player.speedmult = 150
	--flip stuffx
	player.flipped = false
	player.scaleX = 3
	player.targetscaleX = 3
	player.flipspeed = 0.3
	--player collider
	player.collider = world:newCollider("Rectangle", { player.x, player.y, 40, 96 })
	player.collider:setType("dynamic")
	player.collider:setPosition(player.x, player.y)
	player.collider:setFriction(0.5)
	player.collider:setFixedRotation(true) --prevents rotation

	--spritesheet config
	player.sheet = love.graphics.newImage("assets/male_hero_template.png")
	player.grid = anim8.newGrid(128, 128, player.sheet:getWidth(), player.sheet:getHeight())

	--animations
	animations = {}
	animations.idle = anim8.newAnimation(player.grid("1-10", 2), 0.11)
	animations.walk = anim8.newAnimation(player.grid("1-10", 3), 0.11)
	animations.run = anim8.newAnimation(player.grid("1-10", 4), 0.10)
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
end

function drawParallax(background, camera) -- inits camera and parallax background
	local winW, winH = love.graphics.getDimensions()
	local speeds = { 0.05, 0.1, 0.2, 0.35, 0.5, 0.7 }
	local zoom = 1.0 -- adjust zoom
	local baseYOffset = 65 -- move entire background down

	for i = 1, #background do
		local layer = background[i]
		local scale = math.min(winW / layer:getWidth(), winH / layer:getHeight()) * zoom
		local layerW = layer:getWidth() * scale
		local x = (-camera.x * speeds[i]) % layerW

		-- draw twice for seamless wrap
		love.graphics.draw(layer, x - layerW, baseYOffset, 0, scale, scale)
		love.graphics.draw(layer, x, baseYOffset, 0, scale, scale)
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

	--JUMP
	if (w or space) and player.landed then
		player.collider:applyLinearImpulse(0, -1600)
		player.landed = false
	end

	--animation switch
	if running then
		player.animation = animations.run
	elseif walking then
		player.animation = animations.walk
	else
		player.animation = animations.idle
	end

	--smooth flip
	if player.scaleX < player.targetscaleX then
		player.scaleX = math.min(player.scaleX + player.flipspeed, player.targetscaleX)
	elseif player.scaleX > player.targetscaleX then
		player.scaleX = math.max(player.scaleX - player.flipspeed, player.targetscaleX)
	end

	--update player animation
	player.animation:update(1 / 120)

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
		drawParallax(background, camera)

		-- Apply camera transform for world objects
		love.graphics.push()
		love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))

		--platform
		love.graphics.draw(platform.sprite, platform.x, platform.y, 0, 5, 4)

		--player draw
		player.animation:draw(player.sheet, player.x, player.y, 0, player.scaleX, 3, 64, 64)

		--collision debug
		world:draw()

		--update
		love.graphics.pop()
	end)
end
