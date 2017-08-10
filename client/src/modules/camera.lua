local lg = love.graphics
local lm = love.mouse

local camera = {
   x = 0,
   y = 0
}

function camera:set ()
   lg.push()
   lg.translate (-self.x, -self.y)
end

function camera:unset ()
   lg.pop()
end

function camera:move (dx, dy)
   self.x = self.x + (dx or 0)
   self.y = self.y + (dy or 0)
end

function camera:set_position (x, y)
   self.x = x or self.x
   self.y = y or self.y
end

-- returns mouse x and y
function camera:get_mouse_pos ()
   return lm.getX() + self.x, lm.getY() + self.y
end

return camera
