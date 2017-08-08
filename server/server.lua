local socket = require 'socket'
local packer = require 'libs.packer'

local conn = socket.udp()

local players = {}
local player_index = 0

local REQUIRED_PLAYERS = 1
local required_players = REQUIRED_PLAYERS
local auth_sent        = false
local auth_acks        = nil

local update_rate   = 0.1
local last_steptime = nil
local elapsed_time  = nil
local current_step  = nil

local players_to_ack  = nil
local actions_to_send = { cmd = 'actions', serial = 0, inputs = {} }
local actions_to_ack  = { cmd = 'actions', serial = 0, inputs = {} }

function send_auth ()
   for id, player in pairs (auth_acks) do	    
      local msg = packer.to_string ({ cmd = 'auth',
				      id = id })
      
      conn:sendto (msg, player.ip, player.port)
   end
end

function handle_input_packets (data, ip, port)

   -- acknowledgement to client input
   local answer = packer.to_string ({ cmd = 'ack', serial = data.serial })
   conn:sendto (answer, ip, port)

   -- add to list of actions to send
   local id = ip .. "_" .. port .. "_" .. data.serial
   actions_to_send.inputs[id] = data

   actions_to_send.inputs[id].exec_step = current_step +1
   actions_to_send.inputs[id].rand      = math.random (100)

end

function handle_ack_packets (data)

   if not data.ack_type then return end

   if data.ack_type == 'auth' then
      local id = tonumber (data.client_id)

      if id then auth_acks[id] = nil end
      
   elseif data.ack_type == 'actions' then
      local s, id = tonumber (data.serial), tonumber (data.client_id)

      if s and id and s == actions_to_ack.serial then
	 players_to_ack[id] = nil
      end
      
   end
   
end

function update_clients ()

   if packer.table_size (auth_acks) > 0 then
      send_auth()
   end
   
   -- only continue counting steps if all players acknowledged last input
   if current_step and packer.table_size (players_to_ack) then
      local current_steptime = socket.gettime()
      local dt_steptime = current_steptime - last_steptime
      elapsed_time = elapsed_time + dt_steptime

      for _, player in pairs (players) do
	 local msg = packer.to_string ({ cmd     = "step",
					 step    = current_step,
					 dt      = dt_steptime,
					 elapsed = elapsed_time })
	 
	 conn:sendto (msg, player.ip, player.port)
      end
      
      current_step  = current_step +1
      last_steptime = current_steptime
   end
   
   if packer.table_size (players_to_ack) > 0 or
      packer.table_size (actions_to_send.inputs) > 0
   then
      
      -- current step completely acked? do the next step!
      if packer.table_size (players_to_ack) == 0 then

	 players_to_ack = packer.copy (players)

	 actions_to_ack.inputs = actions_to_send.inputs
	 actions_to_ack.serial = actions_to_send.serial
	 
	 actions_to_send.inputs = {}
	 actions_to_send.serial = actions_to_send.serial +1

      end
      
      for _, player in pairs (players_to_ack) do
	 conn:sendto (packer.to_string (actions_to_ack), player.ip, player.port)
      end
   end
end

function reset ()

   conn:settimeout  (0)
   conn:setsockname ('*', 11111)
   
   players = {}
   player_index = 0

   required_players = REQUIRED_PLAYERS
   auth_sent        = false
   auth_acks        = nil

   last_steptime = nil
   current_step  = nil

   players_to_ack  = nil
   actions_to_send = { cmd = 'actions', serial = 0, inputs = {} }
   actions_to_ack  = { cmd = 'actions', serial = 0, inputs = {} }
   
   print ("Clients disconnected, reset server")

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

	 last_steptime, elapsed_time = socket.gettime(), 0
	 current_step  = 0

	 auth_acks = packer.copy (players)
	 send_auth()

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

	 elseif rec_data.packet_type == 'quit' then

	    -- NOTE: lazy, mostly for debug
	    for id, player in pairs (players) do
	       local msg = packer.to_string ({ cmd = 'quit',
					       id  = id })

	       conn:sendto (msg, player.ip, player.port)
	    end

	    reset()
	    
	 else
	    print ("Unknown packet type: ", rec_data.packet_type)
	    
	 end
	 
      elseif ip ~= 'timeout' then
	 error("Unknown network error: ", tostring(msg))

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
