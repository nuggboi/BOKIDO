local input = {}
input.state = {}

input.joystick = nil
input.sprintToggle = false
input.l3WasDown = false

function input.update()
    local i = input.state

    -- get controller
    if not input.joystick then
        local joysticks = love.joystick.getJoysticks()
        input.joystick = joysticks[1]
    end

    local j = input.joystick

    -- =====================
    -- KEYBOARD INPUT
    -- =====================
    local ka = love.keyboard.isDown("a")
    local kd = love.keyboard.isDown("d")
    local ks = love.keyboard.isDown("s")
    local kw = love.keyboard.isDown("w")

    local kspace = love.keyboard.isDown("space")
    local kc = love.keyboard.isDown("c")
    local kshift = love.keyboard.isDown("lshift")

    local kmoveX = (kd and 1 or 0) + (ka and -1 or 0)
    local kmoveY = (ks and 1 or 0) + (kw and -1 or 0)

    -- =====================
    -- GAMEPAD INPUT
    -- =====================
    local gmoveX, gmoveY = 0, 0
    local gspace, gc = false, false
    local sprintPressed = false

    if j then
        local deadzone = 0.2

        local lx = j:getGamepadAxis("leftx")
        local ly = j:getGamepadAxis("lefty")

        if math.abs(lx) > deadzone then
            gmoveX = lx
        end
        if math.abs(ly) > deadzone then
            gmoveY = ly
        end

        gspace = j:isGamepadDown("a")
        gc = j:isGamepadDown("x")
        sprintPressed = j:isGamepadDown("leftstick")
    end

    -- =====================
    -- MERGE INPUT (DO THIS FIRST)
    -- =====================
    i.moveX = (math.abs(gmoveX) > 0) and gmoveX or kmoveX
    i.moveY = (math.abs(gmoveY) > 0) and gmoveY or kmoveY

    -- =====================
    -- SPRINT LOGIC (NOW USES moveX/moveY)
    -- =====================
    if sprintPressed and not input.l3WasDown then
        input.sprintToggle = true
    end
    input.l3WasDown = sprintPressed

    local moveX = i.moveX or 0
    local moveY = i.moveY or 0

    local isMoving = math.abs(moveX) > 0.1 or math.abs(moveY) > 0.1

    if not isMoving then
        input.sprintToggle = false
    end

    -- =====================
    -- FINAL BUTTON STATES
    -- =====================
    i.a = i.moveX < -0.1
    i.d = i.moveX > 0.1
    i.w = i.moveY < -0.1
    i.s = i.moveY > 0.1

    i.space = kspace or gspace
    i.c = kc or gc

    i.shiftDown = kshift or input.sprintToggle

    i.nokeys = (i.moveX == 0 and i.moveY == 0 and not i.c and not i.shiftDown)
end

return input