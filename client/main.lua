local socket = require 'socket'
local packer = require 'libs.packer'

local address, port = 'localhost', 11111

local entities = {}
local updaterate = 0.1

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

local send_input = false

local world = {}
local t

function love.load ()
    t = 0
    
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername(address, port)

    udp:send("auth")
end

function love.mousepressed (x, y, button)
    local x, y
    
    if love.mouse.isDown(2) then
        x, y = love.mouse.getPosition()
        
        input.serial = input.serial +1
        input.right_click = {
            active = true,
            x = x,
            y = y
        }

        send_input = true
    end
end

function love.update (dt)
    t = t + dt

    if start_time then elapsed_time = os.clock() - start_time end

    if t > updaterate then
        if send_input and input.id then
            udp:send(packer.to_string(input))
        end

        t = t - updaterate
    end

    repeat
        data, msg = udp:receive()

        if data then
            if data == 'auth' then
                start_time = os.clock()
                elapsed_time = 0

                print ("authenticated, start time: ", start_time)    
                
                goto cont
            end

            rec_data = packer.to_table(data)

            if rec_data.cmd == 'ack' then
                send_input = false
            elseif rec_data.cmd == 'input' then
                -- TODO: check if values actually exist

                exec_input(rec_data.input)
            else
                print("Unknown command: ", data.cmd)
            end

        elseif msg ~= 'timeout' then
            error("Network error: " .. tostring(msg))
        end

        ::cont::
    until not data
end

local function exec_input(srv_input)
    if srv_input.right_click.active then
        print("right click at ", srv_input.right_click.x, srv_input.right_click.y)
        -- TODO: stub
    end

    if srv_input.spawn_unit.active then
        print("spawning unit at ", srv_input.right_click.x, srv_input.right_click.y)
        -- TODO: stub
    end
end

function love.draw () 
    -- TODO: stub
end