local input = {}
input.state={}
function input.update()
    local i = input.state
    --inputs
	    i.a = love.keyboard.isDown("a")
	    i.d = love.keyboard.isDown("d")
        i.s = love.keyboard.isDown("s")
	    i.w = love.keyboard.isDown("w")
	    i.space = love.keyboard.isDown("space")
		i.c = love.keyboard.isDown("c")
        i.shiftDown = love.keyboard.isDown("lshift")
	    i.nokeys = not (i.a or i.d or i.s or i.w or i.shiftDown)
end
return input