local NetworkHandler = {
   socket = require 'socket',
   conn = nil,

   address = 'localhost',
   port = 11111,

   updaterate = 0.1,
   elapsed_time = 0,
   step_dt      = 0,
   current_step = 0,

   last_update_time = nil
}

function NetworkHandler:load ()
   self.conn = socket.udp()
   
   self.conn:settimeout(0)
   self.conn:setpeername (self.address, self.port)

   self.conn:send ("auth")

   self.last_update_time = self.socket.gettime()
end

function NetworkHandler:update_server ()
   local inputs = Handlers.Input.inputs_to_send

   if client_id and #inputs > 0 then

      -- time diff via socket time
      -- NOTE: networking should only use sockettime
      local now = self.socket.gettime()
      if now - self.last_update_time > self.updaterate then

	 for _, input in pairs (inputs) do
	    --print(packer.to_string(input))
	    print("sending...", now - self.last_update_time,
		  self.updaterate, input.serial)
	    
	    self.conn:send (packer.to_string(input))
	 end
	 
	 self.last_update_time = now
      end
   end
end

function NetworkHandler:quit ()

   local msg = packer.to_string ({ packet_type = 'quit' })
   self.conn:send (msg)
   
end

function NetworkHandler:receive ()

   repeat
      local data, msg = self.conn:receive()

      if data then
	 rec_data = packer.to_table (data)
	 
	 if rec_data.cmd == 'auth' then
	    local id = tonumber (rec_data.id)

	    if id then
	       client_id = id
	       print ("Successfully authenticated with id: " .. client_id)

	       local msg = { packet_type = 'ack',
			     ack_type    = 'auth',
			     client_id   = client_id }

	       self.conn:send (packer.to_string (msg))
	       
	    else
	       error ("Authentication id faulty!")
	    end
            
	 elseif rec_data.cmd == 'ack' then
	    local serial = tonumber (rec_data.serial)
	    if serial then Handlers.Input:remove_input_to_send (serial) end

	 elseif rec_data.cmd == 'step' then
	    local old_step = self.current_step
	    
	    local step    = tonumber (rec_data.step)
	    local elapsed = tonumber (rec_data.elapsed)
	    local dt      = tonumber (rec_data.dt)

	    if step and elapsed and dt then
	       self.current_step = step
	       self.elapsed_time = elapsed
	       self.step_dt      = dt
	    end

	    -- DEBUG:
	    -- print ("- Step " .. self.current_step .. " / Elapsed: "
	    -- 	      .. self.elapsed_time .. "s / dt: " .. self.step_dt .. " -\n")

	    -- NOTE: actionmanager takes delta step
	    Handlers.Action:step (self.current_step - old_step)
	    
	 elseif rec_data.cmd == 'actions' then
	    
	    if rec_data.inputs and rec_data.serial then

	       -- DEBUG:
	       print("-- BEGIN RECEIVED ACTIONS")
	       for id, input in pairs(rec_data.inputs) do
	       	  print("Client " .. input.client_id,
	       		"#" .. input.serial,
	       		"Supposed Step: " .. input.exec_step,
	       		"Command: " .. input.cmd)
	       end
	       print("-- END RECEIVED ACTIONS\n")

	       local msg = { packet_type = 'ack',
			     ack_type    = 'actions',
			     serial      = rec_data.serial,
			     client_id   = client_id }
	       
	       self.conn:send (packer.to_string (msg))

	       for _, input in pairs (rec_data.inputs) do
		  table.insert (Handlers.Action.actions, input)
	       end
	    end

	 elseif rec_data.cmd == 'quit' then
	    love.event.quit()
	    
	 else
	    print ("Unknown command: ", data.cmd)
	 end

      elseif msg ~= 'timeout' then
	 error ("Network error: ", tostring (msg))
      end

      ::cont::
   until not data

end

return NetworkHandler
