local socket = require 'socket'
local packer = require 'libs.packer'

local address, port = 'localhost', 11111

local entity
local updaterate = 0.1

local world = {}
local t

function love.load ()
    t = 0
    
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername(address, port)
    
    math.randomseed(os.time())
    entity = math.random(99999)

    local msg = {ent = entity, cmd = 'at', x = 320, y = 240}
    udp:send(packer.to_string(msg))
end

function love.update (dt)
    t = t + dt

    if t > updaterate then
        local x, y = 0, 0
        if love.keyboard.isDown('up')    then y=y-(20*t) end
		if love.keyboard.isDown('down')  then y=y+(20*t) end
		if love.keyboard.isDown('left')  then x=x-(20*t) end
		if love.keyboard.isDown('right') then x=x+(20*t) end

        local msg = {ent = entity, cmd = 'move', x = x, y = y}
        udp:send(packer.to_string(msg))

        t = t - updaterate
    end

    repeat
        data, msg = udp:receive()

        if data then
            -- ent, cmd, params = data:match("^(%S*) (%S*) (.*)$")
            -- if cmd == 'at' then
            --     local x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
                
            --     assert (x and y)
            --     x, y = tonumber(x), tonumber(y)

            --     world[ent] = {x = x, y = y}
            -- else
            --     print("Unknown command: ", cmd)
            -- end

            rec_data = packer.to_table(data)
            if rec_data.cmd == 'at' then
                -- TODO: check if values actually exist

                world[rec_data.ent] = {x = tonumber(rec_data.x), y = tonumber(rec_data.y)}
            else
                print("Unknown command: ", data.cmd)
            end

        elseif msg ~= 'timeout' then
            error("Network error: " .. tostring(msg))
        end
    until not data
end

function love.draw () 
    local counter = 0;
	for k, v in pairs(world) do
		love.graphics.print(k, v.x, v.y)
        counter = counter +1
	end

    love.graphics.print (counter, 10, 10)
end