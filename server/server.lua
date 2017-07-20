local socket = require 'socket'
local udp = socket.udp()

local packer = require 'libs.packer'

udp:settimeout(0)
udp:setsockname('*', 11111)

local session = {}
local players = {}

local world = {}
local data, msg_or_ip, port_or_nil
local entity, cmd, params

local running = true

local update_counter = 0
local update_rate = 50

local player_index = 0
local start_time = nil
local elapsed_time = nil

local input = {
    id = nil,
    serial = 0,

    selected = {},
    right_click = {
        active = false,
        x = -1,
        y = -1
    },
    spawn_unit = {
        active = false,
        x = -1,
        y = -1
    }
}

print "beginning server loop..."

while running do
    data, msg_or_ip, port_or_nil = udp:receivefrom()

    if data and data == 'auth' and 
    port_or_nil and msg_or_ip ~= 'timeout' then

        -- check if player already connected
        if session[msg_or_ip] then 
            goto cont 
        end
        
        session[msg_or_ip] = true;

        local new_player = {ip = msg_or_ip, port = port_or_nil}
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

        if packer.to_bool(rec_data.right_click.active) then
            -- TODO: stub
            print ("right click packet")
            
            local answer = packer.to_string({cmd = 'ack'})
            udp:sendto(answer, msg_or_ip, port_or_nil)
        end

        if packer.to_bool(rec_data.spawn_unit.active) then
            -- TODO: stub
            print ("spawn unit packet")

            local answer = packer.to_string({cmd = 'ack'})
            udp:sendto(answer, msg_or_ip, port_or_nil)
        end
    
    elseif msg_or_ip ~= 'timeout' then
		error("Unknown network error: "..tostring(msg))
    else
        -- do nothing
	end

    -- periodic updates
    update_counter = update_counter +1
    if update_counter > update_rate then

        for ip, port in pairs(session) do
            for k, v in pairs(world) do
                local msg = packer.to_string({ent = k, cmd = 'at', x = v.x, y = v.y})
                udp:sendto(msg, ip, port)
            end
        end

        update_counter = 0
    end

    ::cont::

    socket.sleep(0.001)
end

print "server process finished"