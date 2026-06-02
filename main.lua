function love.load() -- load all variables, colliders, animations, etc
    --window config
    love.window.setMode(1200, 800, {fullscreen = true, resizable = true})
    love.window.setTitle("BOKIDO")

    --pixel perfect
    love.graphics.setDefaultFilter("nearest", "nearest")

    --library inits
    local moonshine = require("libs/moonshine")
    local bf = require("libs/breezefield-master")

    --physics world init
    world = bf.newWorld(0, 1200) --gravity
    -- Breezefield's world already registers its own callbacks; do not override

    --file inits
    playerconf = require("engine/playerconf")
    playerconf.load()
    animation = require("engine/animation")
    animation.load(player)
    parallax = require("engine/parallax")
    input = require("engine/input")
    movement = require("engine/movement")
    combat = require("engine/combat")
    enemy = require("engine/enemy")

    --shader config
    effect = moonshine(moonshine.effects.scanlines) -- init shader
    effect.scanlines.opacity = 0.25 -- how visible the scanlines are (0-1)
    effect.scanlines.thickness = 1.2 -- width of each scanline

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
    -- ensure fixture userData for contact checks
    if platform.collider.fixture then
        platform.collider.fixture:setUserData(platform.collider)
    end

    --sfx init [VERY CHANGEABLE RN]
    --lungepunchsfx = love.audio.newSource("assets/audio/sfx/atkx/lungepunch/lungepunch1.wav", "static")

    --combat entities
    entities = {player}

    --enemy entity added
    local Enemy = require("engine/enemy")
    local e = Enemy.new({ x = 800, y = -200, patrolMinX = 600, patrolMaxX = 1000 })
    entities[#entities+1] = e
end

function love.update(dt) -- updates physics, movement, animation
    --physics update
    world:update(dt)

    --animation update
    animation.update(player,dt)

    --input update
    input.update()

    --movement update
    movement.update(player, input, animation, camera, dt)

    --combat update
    combat.update(dt)
    combat.updateEntities(entities, dt)
    combat.handle(entities)
    combat.handlePlayerAttack(player,dt)

    --enemy update
    for _, ent in ipairs(entities) do
        if ent.update then ent:update(dt) end
    end

    --CAMERA STUFF FOUND IN MOVEMENT.LUA
end

function love.keypressed(key)
    if key == "f11" then
        local isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    end
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

        --enemy draw
        for _, ent in ipairs(entities) do
            if ent.draw then ent:draw() end
        end

        --collision debug
        --world:draw()

        --hitbox debug
        --combat.draw(entities)

        --update
        love.graphics.pop()
    end)
end