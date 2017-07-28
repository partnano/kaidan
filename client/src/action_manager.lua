local ActionManager = {
   network_manager = nil,
   entity_manager = nil,
   
   actions = {},
   actions_this_step = {}
}

function ActionManager:update ()
   for id, action in pairs(self.actions) do

      local _t
      if action.exec_step then
	 _t = tonumber(action.exec_step)
      end

      if _t and self.network_manager.current_step >= _t then

	 table.insert(self.actions_this_step, action)
	 self.actions[id] = nil
	 
      end
   end

   local function comp_serial (a, b)
      a.serial, b.serial = tonumber(a.serial), tonumber(b.serial)
      a.rand, b.rand = tonumber(a.rand), tonumber(b.rand)

      if a.serial == b.serial then
	 return a.rand < b.rand
      end

      return a.serial < b.serial
   end

   table.sort(self.actions_this_step, comp_serial)

   -- NOTE: debug
   if #self.actions_this_step > 0 then print("-- BEGIN EXEC ACTION") end
   for id, action in ipairs(self.actions_this_step) do

      -- TODO: value check
      print ("Client " .. action.client_id,
	     "#" .. action.serial,
	     "Exec Step " .. self.network_manager.current_step .. ": ",
	     action.cmd, "x: " .. action.pos.x, "y: " .. action.pos.y)

      if action.cmd == 'move' then
	 --self.entity_manager:move(action.selected, action.pos.x, action.pos.y)
      elseif action.cmd == 'spawn' then
	 local x, y = tonumber(action.pos.x), tonumber(action.pos.y)

	 if x and y then
	    self.entity_manager:spawn(x, y)
	 end
      end
      
   end
   -- NOTE: debug
   if #self.actions_this_step > 0 then print("-- END EXEC ACTION\n") end

   self.actions_this_step = {}
end

return ActionManager
