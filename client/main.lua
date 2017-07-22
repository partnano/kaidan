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

-- TODO: change to array to be sent (and remove acknowledged inputs)
local input = {}

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
        
        input = InputStruct:new()

        input.serial = input_serial_counter +1
        input.cmd = 'move'
        input.pos = {x = x, y = y}

        input.send_time = elapsed_time

        send_input = true
    end
end

function love.update (dt)
    t = t + dt

    if start_time then elapsed_time = socket.gettime() - start_time end

    if t > updaterate then
        -- is send_input AND client_id really needed here?
        if send_input and client_id then
            udp:send(packer.to_string(input))
        end

        t = t - updaterate
    end

    repeat
        data, msg = udp:receive()

        if data then
            rec_data = packer.to_table(data)
            
            if rec_data.cmd == 'auth' then
                start_time = socket.gettime()
                elapsed_time = 0
                client_id = tonumber(rec_data.id)

                print ("authenticated, start time: ", start_time)    
            
            elseif rec_data.cmd == 'ack' then
                send_input = false
            
            elseif rec_data.cmd == 'action' then
                -- TODO: check if values actually exist

                exec_actions(rec_data.actions)
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