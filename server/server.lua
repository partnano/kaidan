local socket = require 'socket'
local udp = socket.udp()

local InputStruct = require 'libs.structs.input_struct'

local packer = require 'libs.packer'

udp:settimeout(0)
udp:setsockname('*', 11111)

local session = {}
local players = {}

local world = {}
local data, ip, port
local entity, cmd, params

local running = true

local update_counter = 0
local update_rate = 50

local player_index = 0
local start_time = nil
local elapsed_time = nil

local input = {}

print "beginning server loop..."

while running do
    -- ip can be ip or network message
    -- port can be port or nil
    data, ip, port = udp:receivefrom()

    if data and data == 'auth' and port and ip ~= 'timeout' then

        -- check if player already connected
        if session[ip] then 
            goto cont 
        end
        
        session[ip] = true;

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

        if rec_data.cmd == 'move' then
            -- TODO: stub
            print ("-move- packet")
            
            local answer = packer.to_string({cmd = 'ack', serial = rec_data.serial})
            udp:sendto(answer, ip, port)
        end
    
    elseif ip ~= 'timeout' then
		error("Unknown network error: "..tostring(msg))
    else
        -- do nothing
	end

    -- periodic updates
    -- TODO: change to sockettime
    update_counter = update_counter +1
    if update_counter > update_rate then

        for ip, port in pairs(session) do
            -- TODO: stub
        end

        update_counter = 0
    end

    ::cont::

    socket.sleep(0.001)
end

print "server process finished"