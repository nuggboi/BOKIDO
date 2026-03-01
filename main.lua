function love.load() -- load all variables, colliders, animations, etc
	--window config
	love.window.setMode(1200, 800)
	love.window.setTitle("BOKIDO")

	--pixel perfect
	love.graphics.setDefaultFilter("nearest", "nearest")

	--library inits
	local moonshine = require("libs/moonshine")
	local bf = require("libs/breezefield-master")

	--file inits
	parallax = require("engine/parallax")
	animation = require("engine/animation")
	input = require("engine/input")

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

	--animating engine initialisation
	animation.init(player)

	--camera config
	camera = { x = 0, y = 0, speed = 5 } --speed = how fast it catches up

	--platform config
	platform = {}
	platform.sprite = love.graphics.newImage("assets/platforms/placeholderplatform.png")
	platform.x = -40
	platform.y = 50
	platform.w = platform.sprite:getWidth() * 5
	platform.h = platform.sprite:getHeight() * 4
	--platform collider
	platform.collider = world:newCollider("Rectangle", {520, 62, platform.w, platform.h })
	platform.collider:setType("static")

	--sfx init [VERY CHANGEABLE RN]
	lungepunchsfx = love.audio.newSource("assets/audio/sfx/atkx/lungepunch/lungepunch1.wav", "static")
end

function love.update(dt) -- updates physics, movement, animation
	--physics update
	world:update(dt)
	--animation update
	animation.update(player,dt)
	--input update
	input.update()

	local a = love.keyboard.isDown("a")
	local d = love.keyboard.isDown("d")
    local s = love.keyboard.isDown("s")
	local w = love.keyboard.isDown("w")
	local space = love.keyboard.isDown("space")
    local shiftDown = love.keyboard.isDown("lshift")
	local nokeys = not (a or d or s or w or shiftDown)

	--velocity
	local vx, vy = player.collider:getLinearVelocity()

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
	if input.state.d then
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
	if input.state.a then
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
	if input.state.space and not lungepunching then
		lungepunching = true
		attacktimer = attackduration
	elseif nokeys then
		walking = false
		running = false
		vx = 0
	end

	--animation switch
	if player.isAttacking then
		animation.set(player,"lunge_punch")
	elseif running then
		animation.set(player,"run")
	elseif walking then
		animation.set(player,"walk")
	else
		animation.set(player,"idle")
	end

	--attack stop
	if player.isAttacking then
		player.attackTimer = player.attackTimer - dt
		if player.attackTimer <= 0 then
			player.isAttacking = false
			animation.set(player,"idle")
		end
	end

	--smooth flip
	if player.scaleX < player.targetscaleX then
		player.scaleX = math.min(player.scaleX + player.flipspeed, player.targetscaleX)
	elseif player.scaleX > player.targetscaleX then
		player.scaleX = math.max(player.scaleX - player.flipspeed, player.targetscaleX)
	end

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

		--update
		love.graphics.pop()
	end)
end