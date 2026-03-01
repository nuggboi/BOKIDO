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
	movement = require("engine/movement")

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
	--movement update
	movement.update(player, input, animation, camera, dt, {lunge = lungepunchsfx})

	--CAMERA STUFF FOUND IN MOVEMENT.LUA
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