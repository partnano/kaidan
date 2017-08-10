-- public dependencies (main.lua)
-- Handlers.Network, Handlers.Simulation

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

local camera = require 'src.modules.camera'

local InputHandler = {
   -- networking packets
   InputPacket = require 'libs.structs.input_struct',
   
   inputs_to_send = {},
   serial_counter = 0,

   elapsed_time = 0   
}

function InputHandler:remove_input_to_send (serial)

   for i, input in ipairs (self.inputs_to_send) do
      if input.serial == serial then
	 
	 table.remove (self.inputs_to_send, i)
	 break

      end
   end
end

function InputHandler:mousepressed (x, y, button)
   if client_id then
      local mx, my = camera:get_mouse_pos()

      if button == 1 then Handlers.Simulation:prepare_select (mx, my) end
      
      -- right click
      if button == 2 then
	 local input = self.InputPacket:copy()

	 input.client_id = client_id
	 input.serial    = self.serial_counter
	 input.cmd       = 'move'
	 input.pos       = { x = mx, y = my }
	 
	 input.selected_entities = Handlers.Simulation.selected_entities_ids
	 
	 input.exec_time = Handlers.Network.elapsed_time
	 input.exec_step = Handlers.Network.current_step

	 table.insert (self.inputs_to_send, input)

	 --finish up
	 self.serial_counter = self.serial_counter +1
      end
      
   end
end

function InputHandler:mousereleased (x, y, button)
   if client_id then
      local mx, my = camera:get_mouse_pos()
      
      if button == 1 then Handlers.Simulation:select (mx, my) end
   end
end

function InputHandler:keypressed (key, scancode, isrepeat)
   if client_id then

      if key == 'a' then
	 local input  = self.InputPacket:copy()
	 local mx, my = camera:get_mouse_pos()
	 
	 input.client_id = client_id
	 input.serial    = self.serial_counter
	 input.cmd       = 'spawn'
	 input.pos       = { x = mx, y = my }

	 input.exec_time = Handlers.Network.elapsed_time
	 input.exec_step = Handlers.Network.current_step

	 table.insert (self.inputs_to_send, input)

	 --finish up
	 self.serial_counter = self.serial_counter +1

      elseif key == 'escape' then
	 Handlers.Network:quit()

      end      
   end
end

function InputHandler:keyreleased (key, scancode)
   -- TODO: stub
end

function InputHandler:update (dt)
   -- purely client side / simulation free stuff

   -- TODO: fix double speed corner scroll
   local kb_move = 15 * dt * Handlers.Config.input.scrollspeed.keyboard
   
   if lk.isDown('left')  then camera:move (-kb_move, 0) end
   if lk.isDown('right') then camera:move (kb_move, 0)  end
   if lk.isDown('up')    then camera:move (0, -kb_move) end
   if lk.isDown('down')  then camera:move (0, kb_move)  end

   local ms_move = 15 * dt * Handlers.Config.input.scrollspeed.mouse
   local mx, my = lm.getPosition()
   local sw, sh = lg.getDimensions()

   if mx <= 2     then camera:move (-ms_move, 0) end
   if mx >= sw -2 then camera:move (ms_move, 0)  end
   if my <= 2     then camera:move (0, -ms_move) end
   if my >= sh -2 then camera:move (0, ms_move)  end
   
end

return InputHandler
