local lg = love.graphics
local lm = love.mouse

local Entity = require 'src.entity'

local EntityManager = {
   id_counter = 1,
   entities = {},

   selected_entities_ids = {}, -- only ids should be in here
   selected_entities = {},
   selection = {
      active = false,
      x, y = -1, -1
   }
}

function EntityManager:spawn (x, y)
   local new_ent = Entity:new({ id = id_counter, x = x, y = y })
   table.insert(self.entities, new_ent)

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
   
   for _, ent in pairs(self.entities) do
      local in_x, in_y = false, false

      if is_inverse.x then
	 if ent.x > x2 and ent.x < x1 then in_x = true end
      else
	 if ent.x > x1 and ent.x < x2 then in_x = true end
      end

      if is_inverse.y then
	 if ent.y > y2 and ent.y < y1 then in_y = true end
      else
	 if ent.y > y1 and ent.y < y2 then in_y = true end
      end

      if in_x and in_y then
	 table.insert (new_selections, ent)
      end
   end
   
   self.selection.active = false

   if #new_selections > 0 then
      for _, ent in pairs(self.selected_entities) do
	 ent.selected = false
      end
      
      self.selected_entities = new_selections
      self.selected_entities_ids = {}
      
      -- now new selections
      for _, ent in pairs(self.selected_entities) do
	 ent.selected = true
	 table.insert(self.selected_entities_ids, ent.id)
      end
   end
   
end

function EntityManager:draw ()
   -- entities
   for _, ent in pairs(self.entities) do
      ent:draw()
   end

   -- selection
   if love.mouse.isDown(1) and self.selection.active then
      lg.setColor({255, 255, 255, 255})
      local _x2, _y2 = lm.getX() - self.selection.x, lm.getY() - self.selection.y
      lg.rectangle('line', self.selection.x, self.selection.y, _x2, _y2)
   end
end

return EntityManager
