local NetworkManager = {
   input_manager = nil,

   socket = require 'socket',
   conn = nil,

   address = 'localhost',
   port = 11111,

   updaterate = 0.1,
   start_time = nil,
   elapsed_time = nil,

   last_update_time = nil
}

function NetworkManager:load ()
   self.conn = socket.udp()
   self.conn:settimeout(0)
   self.conn:setpeername(self.address, self.port)

   self.conn:send("auth")

   self.last_update_time = self.socket.gettime()
end

function NetworkManager:update_time ()
   -- elapsed time is for input / action management
   if self.start_time then
      self.elapsed_time = self.socket.gettime() - self.start_time
   end
end

function NetworkManager:update_server ()
   local inputs = self.input_manager.inputs_to_send

   if client_id and #inputs > 0 then

      -- time diff via socket time
      -- NOTE: networking should only use sockettime
      local now = self.socket.gettime()
      if now - self.last_update_time > self.updaterate then

	 for _, input in pairs(inputs) do
	    --print(packer.to_string(input))
	    --print("sending...", _now - last_update_time, updaterate, input.serial)
	    self.conn:send(packer.to_string(input))
	 end
	 
	 self.last_update_time = now
      end
   end
end

function NetworkManager:receive ()
   local data, msg = nil, nil

   repeat
      data, msg = self.conn:receive()

      if data then
	 rec_data = packer.to_table(data)

	 -- NOTE: debug
	 print("\n---- rec_data")
	 packer.print_table(rec_data)
	 print("---- \n")
	 
	 if rec_data.cmd == 'auth' then
	    self.start_time = self.socket.gettime()
	    self.elapsed_time = 0

	    local _id = tonumber(rec_data.id)

	    if _id then
	       client_id = _id
	       print ("authenticated, start time: " .. self.start_time,
		      "id: " .. client_id)
	    else
	       error ("received auth id faulty!")
	    end
            
	 elseif rec_data.cmd == 'ack' then

	    local _s = tonumber(rec_data.serial)
	    if _s then self.input_manager:remove_input_to_send(_s) end
            
	 elseif rec_data.cmd == 'actions' then
	    
	    print("received something")
	    if rec_data.inputs and rec_data.serial then
	       print("sending ack for")
	       packer.print_table(rec_data.inputs)

	       local _answer = {packet_type = 'ack',
				serial = rec_data.serial,
				client_id = client_id}
	       
	       self.conn:send(packer.to_string(_answer))
	       --exec_actions(rec_data.inputs)
	    end
	 else
	    print("Unknown command: ", data.cmd)
	 end

      elseif msg ~= 'timeout' then
	 error("Network error: " .. tostring(msg))
      end

      ::cont::
   until not data

end

return NetworkManager
