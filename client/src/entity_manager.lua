local lg = love.graphics
local lm = love.mouse
local lp = love.physics

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

   entities_to_move = {},
}

function EntityManager:load ()
   self.world = lp.newWorld (0, 0, true)
end

function EntityManager:spawn (x, y)
   local new_ent = Entity:new (self.world, { id = self.id_counter, x = x, y = y })
   table.insert (self.entities, new_ent)

   self.id_counter = self.id_counter +1
end

function EntityManager:prepare_select (x, y)
   self.selection.x, self.selection.y = x, y
   self.selection.active = true
end

function EntityManager:select (x, y)

   local x1, y1 = self.selection.x, self.selection.y
   local x2, y2 = x, y

   -- detect which direction the selection box is
   local is_inverse = { x = false, y = false }
   if x2 < x1 then is_inverse.x = true end
   if y2 < y1 then is_inverse.y = true end

   local new_selections = {}
   
   for _, ent in pairs (self.entities) do
      local in_x, in_y = false, false

      if is_inverse.x
      then
	 if ent.x > x2 and ent.x < x1 then in_x = true end
      else
	 if ent.x > x1 and ent.x < x2 then in_x = true end
      end

      if is_inverse.y
      then
	 if ent.y > y2 and ent.y < y1 then in_y = true end
      else
	 if ent.y > y1 and ent.y < y2 then in_y = true end
      end

      if in_x and in_y then table.insert (new_selections, ent) end
   end
   
   self.selection.active = false

   if #new_selections > 0 then
      for _, ent in pairs(self.selected_entities) do
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

   -- NOTE: debug
   packer.print_table (selected_ids)

   -- TODO: packer patch to recreate arrays?!
   for _, id in pairs (selected_ids) do
      local _id = tonumber (id)

      if _id then
	 for _, ent in pairs (self.entities) do
	    if ent.id == _id then

	       table.insert (self.entities_to_move,
			     { ent = ent, goal = { x = x, y = y } })

	       break

	    end
	 end
      end
      
   end

   -- NOTE: debug
   -- print ("-- UNITS TO MOVE:")
   -- packer.print_table (self.entities_to_move)
   -- print ("")
end

function EntityManager:move (ds, cs)

   local to_remove = {}

   -- ipairs for (deterministic) order
   for i, entity in ipairs (self.entities_to_move) do
      -- NOTE: debug
      print ("Moving unit " .. entity.ent.id, "on step " .. cs)
      
      local goal_reached = entity.ent:move (entity.goal.x, entity.goal.y)

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

return EntityManager
