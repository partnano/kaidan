local socket = require 'socket'
local packer = require 'libs.packer'

local conn = socket.udp()

local players = {}
local player_index = 0

local required_players = 1
local auth_sent        = false

local update_rate      = 0.1
local last_steptime    = nil
local current_step     = nil

local send_actions    = false
local all_acked       = true
local players_to_ack  = nil
local actions_to_send = { cmd = 'actions', serial = 0, inputs = {} }
local actions_to_ack  = { cmd = 'actions', serial = 0, inputs = {} }

function handle_input_packets (data, ip, port)

   -- acknowledgement to client input
   local _answer = packer.to_string ({ cmd = 'ack', serial = data.serial })
   conn:sendto (_answer, ip, port)

   -- add to list of actions to send
   local _id = ip .. "_" .. port .. "_" .. data.serial
   actions_to_send.inputs[_id] = data

   actions_to_send.inputs[_id].exec_step = current_step +1
   actions_to_send.inputs[_id].rand      = math.random (100)

   send_actions = true

end

function handle_ack_packets (data)

   if data.serial
      and tonumber (data.serial) == actions_to_ack.serial
      and tonumber (data.client_id)
   then
      
      players_to_ack[tonumber(data.client_id)] = nil

   end
   
end

function update_clients ()
   
   if send_actions or packer.table_size (actions_to_send.inputs) > 0 then

      if all_acked then
	 players_to_ack = packer.copy (players)
	 all_acked      = false

	 actions_to_ack.inputs = actions_to_send.inputs
	 actions_to_ack.serial = actions_to_send.serial
	 
	 actions_to_send.inputs = {}
	 actions_to_send.serial = actions_to_send.serial +1
      end
      
      for _, player in pairs (players_to_ack) do
	 conn:sendto (packer.to_string (actions_to_ack), player.ip, player.port)
      end

      if packer.table_size (players_to_ack) == 0 then
	 send_actions = false
	 all_acked    = true
      end
      
   end

   if current_step then
      
      local current_steptime = socket.gettime()

      for _, player in pairs (players) do
	 local msg = packer.to_string ({ cmd  = "step",
					 step = current_step,
					 dt   = last_steptime - current_steptime })
	 
	 conn:sendto (msg, player.ip, player.port)
      end
      
      current_step  = current_step +1
      last_steptime = current_steptime
   end
   
end

function main ()

   local running = true
   local last_update_time = socket.gettime()
   
   conn:settimeout  (0)
   conn:setsockname ('*', 11111)

   print "beginning server loop..."

   while running do
      -- ip can be ip or network message
      -- port can be port or nil
      local data, ip, port = conn:receivefrom()

      -- [ AUTH & STARTUP ] --
      if data and data == 'auth' and port and ip ~= 'timeout' then

	 -- check if player already connected
	 local id = ip .. ":" .. port
	 
	 for _, player in pairs (players) do
	    if player.id == id then goto cont end
	 end

	 local new_player = { ip   = ip,
			      port = port,
			      id   = id }
	 
	 players[player_index] = new_player
	 
	 player_index     = player_index +1
	 required_players = required_players -1

	 goto cont
	 
      end

      if required_players == 0 and not auth_sent then

	 last_steptime = socket.gettime()
	 current_step  = 0

	 for id, player in pairs(players) do
	    
	    local _msg = packer.to_string({cmd = 'auth', id = id})
	    conn:sendto(_msg, player.ip, player.port)
	    print("Sent auth packet to ", player.ip, player.port)

	 end

	 auth_sent = true
	 goto cont
	 
      end
      -- [ AUTH & STARTUP ] --

      -- [ ACTIVE SESSION ] --
      if data then
	 rec_data = packer.to_table (data)

	 -- if there is no packet_type it's to be dismissed
	 if not rec_data.packet_type then goto cont end
	    
	 if rec_data.packet_type == 'input' then
	    handle_input_packets (rec_data, ip, port)
	    
	 elseif rec_data.packet_type == 'ack' then
	    handle_ack_packets (rec_data)

	 else
	    print ("Unknown packet type: ", rec_data.packet_type)
	    
	 end
	 
      elseif ip ~= 'timeout' then
	 error("Unknown network error: " .. tostring(msg))

      else
	 -- do nothing

      end

      ::cont::
      
      -- periodic updates
      local now = socket.gettime()
      
      if now - last_update_time > update_rate then
	 update_clients()	 
	 last_update_time = now

      end

      -- [ ACTIVE SESSION ] --

      socket.sleep(0.001)
   end

   print "server process finished"

end

-- [ ENTRY POINT ] --
main()
