local InputManager = {
   -- networking packets
   InputPacket     = require 'libs.structs.input_struct',
   network_manager = nil,
   entity_manager  = nil,
   
   inputs_to_send = {},
   serial_counter = 0,

   elapsed_time = 0   
}

function InputManager:remove_input_to_send (serial)

   for i, input in ipairs (self.inputs_to_send) do
      if input.serial == serial then
	 
	 table.remove (self.inputs_to_send, i)
	 break

      end
   end
end

function InputManager:mousepressed (x, y, button)
   if client_id then

      if button == 1 then self.entity_manager:prepare_select (x, y) end
      
      -- right click
      if button == 2 then
	 local input = self.InputPacket:copy()

	 input.client_id = client_id
	 input.serial    = self.serial_counter
	 input.cmd       = 'move'
	 input.pos       = { x = x, y = y }
	 
	 input.selected_entities = self.entity_manager.selected_entities_ids
	 
	 input.exec_time = self.network_manager.elapsed_time
	 input.exec_step = self.network_manager.current_step

	 table.insert (self.inputs_to_send, input)

	 --finish up
	 self.serial_counter = self.serial_counter +1
      end
      
   end
end

function InputManager:mousereleased (x, y, button)
   if client_id
   then
      if button == 1 then self.entity_manager:select (x, y) end
   end
end

function InputManager:keypressed (key, scancode, isrepeat)
   if client_id then

      -- right click
      if key == 'a' then
	 local input = self.InputPacket:copy()

	 input.client_id = client_id
	 input.serial    = self.serial_counter
	 input.cmd       = 'spawn'
	 input.pos       = { x = love.mouse.getX(), y = love.mouse.getY() }

	 input.exec_time = self.network_manager.elapsed_time
	 input.exec_step = self.network_manager.current_step

	 table.insert (self.inputs_to_send, input)

	 --finish up
	 self.serial_counter = self.serial_counter +1
      end
      
   end
end

function InputManager:keyreleased (key, scancode)
   -- TODO: stub
end

return InputManager
