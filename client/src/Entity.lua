local lg = love.graphics
local lp = love.physics

local Entity = {
   id     = -1,
   speed  = 30,
   radius = 20,
   rend_x = 0,
   rend_y = 0,
   
   selected = false,

   body    = nil,
   shape   = nil,
   fixture = nil
}

function Entity:new (world, o)
   o = o or {}
   setmetatable (o, self)
   self.__index = self
   
   local _x, _y = o._x, o._y
   o._x, o._y = nil, nil
   
   -- o._x and o._y are provided by spawn function in entity_manager !
   o.body    = lp.newBody (world, _x, _y, 'dynamic')
   o.shape   = lp.newCircleShape (o.radius +3)
   o.fixture = lp.newFixture (o.body, o.shape)

   o.rend_x = _x
   o.rend_y = _y
  
   return o
end

function Entity:draw ()
   -- current x y
   local cx, cy = self:get_coords()
   local rx, ry = self.rend_x, self.rend_y
   
   if self.selected then
      lg.setColor ({100, 255, 100, 120})
      lg.circle ('fill', rx, ry, self.radius +3)
   end

   -- interpolated render
   lg.setColor ({ 255, 255, 255, 255 })
   lg.circle ('fill', rx, ry, self.radius)

   -- simulation body
   lg.setColor ({ 255, 0, 0, 255 })
   lg.circle ('line', cx, cy, self.radius)

   -- print (self.id, ":", rx, ry, "/", cx, cy)
   
   lg.setColor ({ 255, 255, 255, 255 })

end

function Entity:move_interpolation (dt, dts)
   
   local gx, gy = self:get_coords()

   if gx ~= self.rend_x or gy ~= self.rend_y then

      local move_vec = self:prep_move (self.rend_x, self.rend_y, gx, gy)

      local delta_x, delta_y = self.rend_x - gx, self.rend_y - gy
      local abs_delta_x, abs_delta_y = math.abs (delta_x), math.abs (delta_y)

      local jump_dist = 5
      
      if abs_delta_x <= jump_dist then
	 self.rend_x = gx
      else
	 self.rend_x = self.rend_x + (move_vec.x * self.speed * dt/2)
      end

      if abs_delta_y <= jump_dist then
	 self.rend_y = gy
      else
	 self.rend_y = self.rend_y + (move_vec.y * self.speed * dt/2)
      end

   end
end

-- simple point a to point b movement
-- returns boolean for if the goal is reached
function Entity:move (gx, gy, entities)

   -- DEBUG:
   -- print ("Moving entity: " .. self.id)
   
   -- current x y
   local cx, cy = self:get_coords()

   -- NOTE: future optimization: don't always do the prep vector?
   local move_vec = self:prep_move (cx, cy, gx, gy)
   
   local delta_x, delta_y = cx - gx, cy - gy
   local abs_delta_x, abs_delta_y = math.abs (delta_x), math.abs (delta_y)

   if abs_delta_x >= move_vec.x then
      if self:check_collision (cx + move_vec.x, cy, entities) then

	 self.body:setX (cx + move_vec.x)

      end
   end

   if abs_delta_y >= move_vec.y then
      if self:check_collision (cx, cy + move_vec.y, entities) then

	 self.body:setY (cy + move_vec.y)
	 
      end
   end

   if math.abs (cx - gx) < self.speed and math.abs (cy - gy) < self.speed then
      if self:check_collision (gx, gy, entities) then
	 
	 self.body:setX (gx)
	 self.body:setY (gy)
	 
	 return true
      end
   end
   
   return false -- still moving

end

function Entity:prep_move (cx, cy, gx, gy)
   
   local move_vec = { x = gx - cx, y = gy - cy }
   local length   = math.sqrt (move_vec.x ^2 + move_vec.y ^2)

   -- normalize move vector and add entity speed
   move_vec = { x = move_vec.x / length, y = move_vec.y / length }
   move_vec = { x = move_vec.x * self.speed, y = move_vec.y * self.speed }

   return move_vec
   
end

-- NOTE:
-- returns true on success -> no other unit in the way
-- returns false on fail   -> another unit in the way
function Entity:check_collision (gx, gy, entities)
   for _, ent in pairs (entities) do

      if ent.id == self.id then
	 goto cont
      end

      local own_coll = self.shape:getRadius()
      
      local ex, ey = ent:get_coords()
      local e_coll = ent.shape:getRadius()

      if ((gx + own_coll >= ex - e_coll and gx + own_coll <= ex + e_coll) or
	    (gx - own_coll >= ex - e_coll and gx - own_coll <= ex + e_coll)) and
	 ((gy + own_coll >= ey - e_coll and gy + own_coll <= ey + e_coll or
	     gy - own_coll >= ey - e_coll and gy - own_coll <= ey + e_coll))
      then

	 return false

      end

      ::cont::
   end

   return true
end

function Entity:get_coords ()

   return self.body:getX(), self.body:getY()
   
end

return Entity
