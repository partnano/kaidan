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

local inputs_to_send = {}

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

        input.serial = input_serial_counter
        input.cmd = 'move'
        input.pos = {x = x, y = y}

        input.send_time = elapsed_time

        table.insert(inputs_to_send, input)

        --finish up
        input_serial_counter = input_serial_counter +1
    end
end

function love.update (dt)
    -- TODO: change updaterate to sockettime
    t = t + dt

    if start_time then elapsed_time = socket.gettime() - start_time end

    -- send stuff
    if t > updaterate then
        -- is send_input AND client_id really needed here?
        if client_id and #inputs_to_send > 0 then
            for _, input in ipairs(inputs_to_send) do
            
                udp:send(packer.to_string(input))
            
            end
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
                -- TODO: delete acknowledged input

                for i, input in ipairs(inputs_to_send) do
                    if input.serial == tonumber(rec_data.serial) then
                        table.remove(inputs_to_send, i)
                        break
                    end
                end
            
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