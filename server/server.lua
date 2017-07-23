local socket = require 'socket'
local udp = socket.udp()

-- local InputStruct = require 'libs.structs.input_struct' -- do I really need that here?

local packer = require 'libs.packer'

local session = {}
local players = {}

local world = {}
local data, ip, port
local entity, cmd, params

local running = true

local player_index = 0
local start_time = nil
local elapsed_time = nil

local last_update_time = socket.gettime()
local update_rate = 0.1

local send_actions = false
local actions = { cmd = 'actions', serial = 0, inputs = {} }

udp:settimeout(0)
udp:setsockname('*', 11111)

print "beginning server loop..."

while running do
   -- ip can be ip or network message
   -- port can be port or nil
   data, ip, port = udp:receivefrom()

   if data and data == 'auth' and port and ip ~= 'timeout' then

      -- check if player already connected
      local _id = ip .. ":" .. port
      if session[_id] then 
	 goto cont 
      end
      
      session[_id] = {ip = ip, port = port}
      
      local new_player = {ip = ip, port = port}
      players[player_index] = new_player

      -- TODO: start as soon as enough players connected
      -- for now this is only for a single client ... which is rather useless
      start_time = socket.gettime()
      elapsed_time = 0

      local _msg = packer.to_string({cmd = 'auth', id = player_index})

      udp:sendto(_msg, new_player.ip, new_player.port)
      print("Sent auth packet to ", new_player.ip, new_player.port)
      
      player_index = player_index +1

      goto cont
   end

   if data then
      rec_data = packer.to_table(data)
      
      packer.print_table(rec_data)
      print(rec_data.packet_type)

      if rec_data.packet_type == 'input' then

	 -- ack
	 local _answer = packer.to_string({cmd = 'ack', serial = rec_data.serial})
	 udp:sendto(_answer, ip, port)

	 local _id = ip .. "_" .. port .. "_" .. rec_data.serial
	 actions.inputs[_id] = rec_data

	 -- TODO: change 0.2 to conf variable
	 actions.inputs[_id].exec_time = rec_data.exec_time + 0.2

	 send_actions = true
	 
      end
      
   elseif ip ~= 'timeout' then
      error("Unknown network error: "..tostring(msg))
   else
      -- do nothing
   end

   ::cont::
   
   -- periodic updates
   if not last_update_time then last_update_time = socket.gettime() end

   
   local _now = socket.gettime()
   if _now - last_update_time > update_rate then

      if send_actions then
	 for _, info in pairs(session) do
	    udp:sendto(packer.to_string(actions), info.ip, info.port)
	 end
	 
	 -- TODO: only do this after client acks !!!
	 actions.inputs = {}
	 send_actions = false
      end

      last_update_time = _now
   end

   socket.sleep(0.001)
end

print "server process finished"
