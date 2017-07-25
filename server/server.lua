local socket = require 'socket'
local udp = socket.udp()

-- local InputStruct = require 'libs.structs.input_struct' -- do I really need that here?

local packer = require 'libs.packer'

local session = {} -- these two are kinda the same, but I need two different ids...
local players = {}

local world = {}
local data, ip, port
local entity, cmd, params

local running = true

local player_index = 0
local start_time = nil
local elapsed_time = nil

local required_players = 1
local auth_sent = false

local last_update_time = nil
local update_rate = 0.1

local send_actions = false
local actions_to_send = { cmd = 'actions', serial = 0, inputs = {} }
local actions_to_ack = { cmd = 'actions', serial = 0, inputs = {} }
local players_to_ack = nil
local all_acked = true

udp:settimeout(0)
udp:setsockname('*', 11111)

print "beginning server loop..."

while running do
   -- ip can be ip or network message
   -- port can be port or nil
   data, ip, port = udp:receivefrom()

   -- [ AUTH & STARTUP ] --
   if data and data == 'auth' and port and ip ~= 'timeout' then

      -- check if player already connected
      local _id = ip .. ":" .. port
      if session[_id] then 
	 goto cont 
      end

      local new_player = {ip = ip, port = port}
      session[_id] = new_player
      players[player_index] = new_player
      
      player_index = player_index +1
      required_players = required_players -1

      goto cont
   end

   if required_players == 0 and not auth_sent then

      start_time = socket.gettime()
      elapsed_time = 0

      for id, player in pairs(players) do
	 
	 local _msg = packer.to_string({cmd = 'auth', id = id})
	 udp:sendto(_msg, player.ip, player.port)
	 print("Sent auth packet to ", player.ip, player.port)

      end

      auth_sent = true
      goto cont
   end
   -- [ AUTH & STARTUP ] --

   -- [ ACTIVE SESSINO ] --
   if data then
      rec_data = packer.to_table(data)

      -- NOTE: debug
      print("\n---- rec_data")
      packer.print_table(rec_data)
      print("---- \n")

      if rec_data.packet_type then
	 
	 if rec_data.packet_type == 'input' then

	    -- acknowledgement about client input
	    local _answer = packer.to_string({cmd = 'ack', serial = rec_data.serial})
	    udp:sendto(_answer, ip, port)

	    local _id = ip .. "_" .. port .. "_" .. rec_data.serial
	    actions_to_send.inputs[_id] = rec_data

	    -- TODO: change 0.2 to conf variable
	    actions_to_send.inputs[_id].exec_time = rec_data.exec_time + 0.2

	    send_actions = true

	 elseif rec_data.packet_type == 'ack' then
	    if rec_data.serial
	       and tonumber(rec_data.serial) == actions_to_ack.serial
	       and rec_data.client_id
	    then
	       players_to_ack[tonumber(rec_data.client_id)] = nil
	       packer.print_table(players_to_ack)
	    end

	 end
      end
      
   elseif ip ~= 'timeout' then
      error("Unknown network error: " .. tostring(msg))
   else
      -- do nothing
   end

   ::cont::
   
   -- periodic updates
   if not last_update_time then last_update_time = socket.gettime() end

   local _now = socket.gettime()
   if _now - last_update_time > update_rate then

      if send_actions then
	 
	 if all_acked then
	    players_to_ack = packer.copy(players)
	    all_acked = false

	    actions_to_ack.inputs = actions_to_send.inputs
	    actions_to_ack.serial = actions_to_send.serial
	    
	    actions_to_send.inputs = {}
	    actions_to_send.serial = actions_to_send.serial +1
	 end
	 
	 for _, info in pairs(players_to_ack) do
	    udp:sendto(packer.to_string(actions_to_ack), info.ip, info.port)
	 end

	 if packer.table_size(players_to_ack) == 0 then
	    send_actions = false
	    all_acked = true
	 end
	 
      end

      last_update_time = _now
   end

   -- [ ACTIVE SESSION ] --

   socket.sleep(0.001)
end

print "server process finished"
