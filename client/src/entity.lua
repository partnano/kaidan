local lg = love.graphics
local lp = love.physics

local Entity = {
   id    = -1,
   --x, y  = 0, 0,
   r     = 20,
   speed = 15,

   move_vec = { x = 0, y = 0 },
   
   selected = false,

   body    = nil,
   shape   = nil,
   fixture = nil
}

function Entity:new (world, o)
   o = o or {}
   setmetatable (o, self)
   self.__index = self

   -- o.x and o.y are provided by spawn function in entity_manager !
   o.body    = lp.newBody (world, o.x, o.y, 'dynamic')
   o.shape   = lp.newCircleShape (o.r +3)
   o.fixture = lp.newFixture (o.body, o.shape)
   
   return o
end

function Entity:draw ()
   -- current x y
   local cx, cy = self:get_coords()

   if self.selected then
      lg.setColor ({100, 255, 100, 120})
      lg.circle ('fill', cx, cy, self.r +3)
   end
   
   lg.setColor ({ 255, 255, 255, 255 })
   lg.circle ('fill', cx, cy, self.r)

end

-- simple point a to point b movement
-- returns boolean for if the goal is reached
function Entity:move (gx, gy, entities)

   -- DEBUG:
   print ("Moving entity: " .. self.id)
   
   -- flags to be used here
   -- local move_x, move_y = false, false
   -- local goal_reached = false
   -- local coll_x, coll_y = false, false
   
   -- current x y
   local cx, cy = self:get_coords()

   -- NOTE: future optimization: don't always do the prep vector?
   self.move_vec = self:prep_move (gx, gy)
   
   local delta_x, delta_y = cx - gx, cy - gy
   local abs_delta_x, abs_delta_y = math.abs (delta_x), math.abs (delta_y)

   if abs_delta_x >= self.move_vec.x then
      -- DEBUG:
      -- print ("trying to move x")
      
      if self:check_collision (cx + self.move_vec.x, cy, entities) then

	 print ("moving x")
	 self.body:setX (cx + self.move_vec.x)

      end
   end

   if abs_delta_y >= self.move_vec.y then

      -- DEBUG:
      --print ("trying to move y")
      
      if self:check_collision (cx, cy + self.move_vec.y, entities) then

	 --print ("moving y")
	 self.body:setY (cy + self.move_vec.y)
	 
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

function Entity:prep_move (gx, gy)

   -- current x y
   local cx, cy = self:get_coords()
   
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
