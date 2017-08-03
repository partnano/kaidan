local lg = love.graphics
local lm = love.mouse
local lp = love.physics
local lt = love.timer
local lk = love.keyboard

local Entity = require 'src.entity'

local EntityManager = {
   id_counter = 1,
   entities   = {},
   world      = nil,

   selected_entities_ids = {}, -- only ids should be in here
   selected_entities     = {},
   selection = {
      active = false,
      x, y   = -1, -1
   },

   last_click = 0,

   entities_to_move = {},
}

function EntityManager:load ()
   self.world = lp.newWorld (0, 0, true)
end

function EntityManager:spawn (x, y)
   local new_ent = Entity:new (self.world, { id = self.id_counter, _x = x, _y = y })
   table.insert (self.entities, new_ent)

   self.id_counter = self.id_counter +1
end

function EntityManager:prepare_select (x, y)
   self.selection.x, self.selection.y = x, y
   self.selection.active = true
end

function EntityManager:select (x, y)

   self.selection.active = false
   
   local x1, y1 = self.selection.x, self.selection.y
   local x2, y2 = x, y

   -- detect which direction the selection box is
   local is_inverse = { x = false, y = false }
   if x2 < x1 then is_inverse.x = true end
   if y2 < y1 then is_inverse.y = true end

   -- [ CLICK DETECTION ] --
   
   -- detect if it was a click
   local is_click = false
   local x_diff = math.abs (x1 - x2)
   local y_diff = math.abs (y1 - y2)

   if x_diff < 5 and y_diff < 5 then is_click = true end

   -- [ DOUBLECLICK DETECTION ] --
   
   local is_doubleclick = false

   if is_click then
      -- client time for client stuff
      local time_now  = lt.getTime() * 1000
      local time_diff = time_now - self.last_click

      if time_diff < 250 then is_doubleclick = true end
      self.last_click = time_now
   end

   if is_click and lk.isDown('lctrl') then is_doubleclick = true end

   -- [ SELECTION ] --
   
   local new_selections = {}
   
   for _, ent in pairs (self.entities) do
      -- TODO: get draw coords
      local ex, ey = ent:get_coords()
      local er     = ent.shape:getRadius()
      
      local in_x, in_y = false, false

      if is_click then
	 
	 if x1 > ex - er and x1 < ex + er then in_x = true end
	 if y1 > ey - er and y1 < ey + er then in_y = true end

	 if in_x and in_y then

	    table.insert (new_selections, ent)
	    break
	    
	 end
	 
      else
	 
	 if is_inverse.x then
	    if ex > x2 and ex < x1 then in_x = true end
	 else
	    if ex > x1 and ex < x2 then in_x = true end
	 end

	 if is_inverse.y then
	    if ey > y2 and ey < y1 then in_y = true end
	 else
	    if ey > y1 and ey < y2 then in_y = true end
	 end

	 if in_x and in_y then table.insert (new_selections, ent) end

      end
   end

   if #new_selections > 0 then
      -- TODO: only units on screen (once camera movement exists)
      -- TODO: only units of double_clicked type (once more entities exist)
      if is_doubleclick then
	 new_selections = {}
	 
	 for _, ent in pairs (self.entities) do
	    table.insert (new_selections, ent)
	 end
      end
      
      for _, ent in pairs (self.selected_entities) do
	 ent.selected = false
      end
      
      self.selected_entities = new_selections
      self.selected_entities_ids = {}
      
      -- now new selections
      for _, ent in pairs (self.selected_entities) do
	 ent.selected = true
	 table.insert (self.selected_entities_ids, ent.id)
      end
   end
   
end

function EntityManager:add_to_move_queue (selected_ids, x, y)
   -- TODO: calculate customized goal coords

   for _, id in ipairs (selected_ids) do
      local _id = tonumber (id)

      if _id then
	 for _, ent in pairs (self.entities) do
	    if ent.id == _id then

	       -- if entity is already moving replace it in move queue
	       for i, moving in pairs (self.entities_to_move) do
		  if ent.id == moving.ent.id then
		     self.entities_to_move[i] =
			{ ent = ent, goal = { x = x, y = y }, init = true }

		     goto break2
		  end
	       end

	       -- else just insert it
	       table.insert (self.entities_to_move,
			     { ent = ent, goal = { x = x, y = y }, init = true })

	       ::break2::
	       break

	    end
	 end
      end
   end

   -- DEBUG:
   -- print ("-- UNITS TO MOVE:")
   -- packer.print_table (self.entities_to_move)
   -- print ("")
end

function EntityManager:move (ds, cs)
   
   local to_remove = {}

   -- ipairs for (deterministic) order
   for i, entity in ipairs (self.entities_to_move) do
      -- DEBUG:
      -- print ("Moving unit " .. entity.ent.id, "on step " .. cs)
      
      local goal_reached = entity.ent:move (entity.goal.x, entity.goal.y,
					    self.entities)

      entity.init = false
      
      if goal_reached then table.insert (to_remove, i) end
   end

   -- because of ipairs the elements need to be removed in a more annoying fashion
   table.sort (to_remove, function (a, b) return a > b end)
   
   for _, i in ipairs(to_remove) do
      table.remove (self.entities_to_move, i)
   end
   
end

function EntityManager:draw ()
   -- entities
   for _, ent in pairs (self.entities) do
      ent:draw()
   end

   -- selection
   if love.mouse.isDown (1) and self.selection.active
   then
      local _x2 = lm.getX() - self.selection.x
      local _y2 = lm.getY() - self.selection.y

      lg.setColor ({255, 255, 255, 255})
      lg.rectangle ('line', self.selection.x, self.selection.y, _x2, _y2)
   end
end

function EntityManager:update (dt)
   self.world:update (dt)

   for _, ent in pairs (self.entities) do
      ent:move_interpolation (dt)
   end
end

return EntityManager
