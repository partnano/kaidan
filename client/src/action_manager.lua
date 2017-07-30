local ActionManager = {
   network_manager = nil,
   entity_manager = nil,
   
   actions = {},
   actions_this_step = {}
}

-- TODO: do most of the update in here (decoupling from love update)
function ActionManager:step (ds)

   -- DETERMINING WHICH ACTIONS TO DO THIS STEP
   for id, action in pairs (self.actions) do

      local _t
      if action.exec_step then
	 _t = tonumber (action.exec_step)
      end

      if _t and self.network_manager.current_step >= _t then

	 table.insert (self.actions_this_step, action)
	 self.actions[id] = nil
	 
      end
   end

   -- DETERMINING ORDER OF ACTONS
   local function comp_serial (a, b)
      a.serial, b.serial = tonumber(a.serial), tonumber(b.serial)
      a.rand, b.rand = tonumber(a.rand), tonumber(b.rand)

      if a.serial == b.serial then
	 return a.rand < b.rand
      end

      return a.serial < b.serial
   end

   table.sort(self.actions_this_step, comp_serial)

   -- EXECUTING ACTIONS
   -- NOTE: debug
   if #self.actions_this_step > 0 then print("-- BEGIN EXEC ACTION") end
   for id, action in ipairs(self.actions_this_step) do

      -- TODO: value check
      print ("Client " .. action.client_id,
	     "Input #" .. action.serial,
	     "Exec Step " .. self.network_manager.current_step .. ": ",
	     action.cmd, "x: " .. action.pos.x, "y: " .. action.pos.y)

      if action.cmd == 'move' then
	 -- transform to array
	 -- NOTE: UGLY!
	 action.selected_entities =
	    packer.to_array (packer.to_string (action.selected_entities))
	 
	 self.entity_manager:add_to_move_queue (action.selected_entities,
						action.pos.x, action.pos.y)
	 
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

   -- PERIODIC CLIENT UPDATES
   
   self.entity_manager:move (ds, self.network_manager.current_step)
end

function ActionManager:update ()
   -- TODO: stub
end

return ActionManager
