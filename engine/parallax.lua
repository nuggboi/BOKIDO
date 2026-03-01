-- parallax.lua
local parallax = {}

background = {
    love.graphics.newImage("assets/background/1.png"),
    love.graphics.newImage("assets/background/2.png"),
    love.graphics.newImage("assets/background/3.png"),
    love.graphics.newImage("assets/background/4.png"),
    love.graphics.newImage("assets/background/5.png"),
    love.graphics.newImage("assets/background/6.png"),
}

function parallax.draw(background, camera)
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

return parallax