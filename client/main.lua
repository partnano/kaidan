local socket = require 'socket'
local packer = require 'libs.packer'

local InputStruct = require 'libs.structs.input_struct'

local address, port = 'localhost', 11111

local entities = {}
local updaterate = 0.1

local start_time = nil
local elapsed_time = nil

local client_id = nil
local input_serial_counter = 0

local inputs_to_send = {}

local world = {}
local last_update_time = socket.gettime()

function love.load ()
   t = 0
   
   udp = socket.udp()
   udp:settimeout(0)
   udp:setpeername(address, port)

   udp:send("auth")
end

function love.mousepressed (x, y, button)
   if client_id then
      
      if love.mouse.isDown(2) then

	 -- FIXME: to do this correctly packer needs to support metatables (objects)
	 input = InputStruct:new()

	 input.packet_type = 'input'
	 input.client_id = client_id
	 input.serial = input_serial_counter
	 input.cmd = 'move'
	 input.pos = {x = x, y = y}

	 input.exec_time = elapsed_time

	 table.insert(inputs_to_send, input)

	 --finish up
	 input_serial_counter = input_serial_counter +1
      end

   end
end

function love.update (dt)

   -- elapsed time is for input / action management
   if start_time then elapsed_time = socket.gettime() - start_time end

   -- send stuff
   if client_id and #inputs_to_send > 0 then

      -- time diff via socket time
      -- NOTE: networking should only use sockettime
      local _now = socket.gettime()
      if _now - last_update_time > updaterate then
	 for _, input in pairs(inputs_to_send) do
	    
	    --print(packer.to_string(input))
	    --print("sending...", _now - last_update_time, updaterate, input.serial)
	    udp:send(packer.to_string(input))
	    
	 end
	 
	 last_update_time = _now
      end

   end

   repeat
      data, msg = udp:receive()

      if data then
	 rec_data = packer.to_table(data)
	 
	 if rec_data.cmd == 'auth' then
	    start_time = socket.gettime()
	    elapsed_time = 0
	    client_id = tonumber(rec_data.id)

	    print ("authenticated, start time: " .. start_time, "id: " .. client_id)    
            
	 elseif rec_data.cmd == 'ack' then

	    for i, input in ipairs(inputs_to_send) do
	       if input.serial == tonumber(rec_data.serial) then
		  table.remove(inputs_to_send, i)
		  break
	       end
	    end
            
	 elseif rec_data.cmd == 'actions' then
	    -- TODO: check if values actually exist

	    print("received something")
	    if rec_data.inputs then
	       packer.print_table(rec_data.inputs)
	    end
	    --exec_actions(rec_data.inputs)
	 else
	    print("Unknown command: ", data.cmd)
	 end

      elseif msg ~= 'timeout' then
	 error("Network error: " .. tostring(msg))
      end

      ::cont::
   until not data
end

local function exec_actions(actions)
   -- TODO: stub
end

function love.draw () 
   -- TODO: stub
end
