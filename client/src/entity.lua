local lg = love.graphics

local Entity = {
   id = -1,
   x, y = 0, 0,
   selected = false
}

function Entity:new (o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   return o
end

function Entity:draw ()
   lg.setColor({ 255, 255, 255, 255 })
   lg.circle('fill', self.x, self.y, 10)

   if self.selected then
      lg.setColor({100, 255, 100, 120})
      lg.circle('line', self.x, self.y, 12)
   end

   lg.setColor({ 255, 255, 255, 255 })
end

return Entity
