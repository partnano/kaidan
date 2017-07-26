local InputManager = {
   -- networking packets
   InputPacket = require 'libs.structs.input_struct',
   network_manager = nil,
   
   inputs_to_send = {},
   serial_counter = 0,

   elapsed_time = 0
   
}

function InputManager:remove_input_to_send (serial)

   for i, input in ipairs(self.inputs_to_send) do
      if input.serial == serial then

	 table.remove(self.inputs_to_send, i)
	 break

      end
   end
end

function InputManager:mousepressed (x, y, button)
   if client_id then

      -- right click
      if button == 2 then
	 local input = self.InputPacket:copy()

	 input.client_id = client_id
	 input.serial = self.serial_counter
	 input.cmd = 'move'
	 input.pos = {x = x, y = y}

	 input.exec_time = self.network_manager.elapsed_time

	 table.insert(self.inputs_to_send, input)

	 --finish up
	 self.serial_counter = self.serial_counter +1
      end
      
   end
end

function InputManager:mousereleased (x, y, button)
   -- TODO: stub
end

function InputManager:keypressed (key, scancode, isrepeat)
   -- TODO: stub
end

function InputManager:keyreleased (key, scancode)
   -- TODO: stub
end

function InputManager:update (dt, elapsed)
   self.elapsed_time = elapsed
end

return InputManager
