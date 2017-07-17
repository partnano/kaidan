local socket = require 'socket'
local udp = socket.udp()

local packer = require 'libs.packer'

udp:settimeout(0)
udp:setsockname('*', 11111)

local session = {}

local world = {}
local data, msg_or_ip, port_or_nil
local entity, cmd, params

local running = true

local update_counter = 0;
local update_rate = 50;

print "beginning server loop..."

while running do
    data, msg_or_ip, port_or_nil = udp:receivefrom()

    if data and port_or_nil and msg_or_ip ~= 'timeout' then
        print (msg_or_ip)
        session[msg_or_ip] = port_or_nil
    end

    if data then
        rec_data = packer.to_table(data)

        if rec_data.cmd == 'move' then
            local x, y = rec_data.x, rec_data.y
            
            assert(x and y)
            x, y = tonumber(x), tonumber(y)
            
            local ent = world[rec_data.ent] or {x = 0, y = 0}
			world[rec_data.ent] = {x = ent.x + x, y = ent.y + y}

        elseif rec_data.cmd == 'at' then
            local x, y = rec_data.x, rec_data.y
			
            assert(x and y)
			
            world[rec_data.ent] = {x = tonumber(x), y = tonumber(y)}

        elseif rec_data.cmd == 'quit' then
            running = false

        else
            print('Unrecognized command: ', cmd)
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

    socket.sleep(0.001)
end

print "server process finished"