local ActionManager = {
   network_manager = nil,
   
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

   table.sort(self.actions_this_step,
	      function(a, b)
		 -- FIXME: 2+ players, same serial ?
		 return tonumber(a.serial) < tonumber(b.serial)
	      end
   )

   -- NOTE: debug
   if #self.actions_this_step > 0 then print("-- BEGIN EXEC ACTION") end
   for id, action in ipairs(self.actions_this_step) do

      	 -- TODO: value check
	 print ("#" .. action.serial,
		"Exec Step " .. self.network_manager.current_step .. ": ",
		action.cmd, "x: " .. action.pos.x, "y: " .. action.pos.y)
      
   end
   -- NOTE: debug
   if #self.actions_this_step > 0 then print("-- END EXEC ACTION\n") end

   self.actions_this_step = {}
end

return ActionManager
