local lg = love.graphics
local lp = love.physics

local Entity = {
   id    = -1,
   x, y  = 0, 0,
   r     = 10,
   speed = 10,
   
   selected = false,

   body    = nil,
   shape   = nil,
   fixture = nil
}

function Entity:new (world, o)
   o = o or {}
   setmetatable (o, self)
   self.__index = self

   o.body    = lp.newBody (world, o.x, o.y, 'dynamic')
   o.shape   = lp.newCircleShape (o.r +3)
   o.fixture = lp.newFixture (o.body, o.shape)
   
   return o
end

function Entity:draw ()
   lg.setColor ({ 255, 255, 255, 255 })
   lg.circle ('fill', self.x, self.y, self.r)

   if self.selected
   then
      lg.setColor ({100, 255, 100, 120})
      lg.circle ('line', self.x, self.y, self.r +2)
   end

   lg.setColor ({ 255, 255, 255, 255 })
end

function Entity:move (gx, gy)
   -- TODO: stub
   return true
end

return Entity
