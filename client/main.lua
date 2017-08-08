-- globals
lg = love.graphics
lt = love.timer

client_id = nil

-- general libs
packer = require 'libs.packer'

-- managers
local input_manager   = require 'src.input_manager'
local action_manager  = require 'src.action_manager'
local network_manager = require 'src.network_manager'
local entity_manager  = require 'src.entity_manager'

function love.load ()
   input_manager.network_manager = network_manager
   input_manager.entity_manager  = entity_manager
   
   network_manager.input_manager  = input_manager
   network_manager.action_manager = action_manager

   action_manager.network_manager = network_manager
   action_manager.entity_manager  = entity_manager
   
   entity_manager:load()
   network_manager:load()
end

function love.mousepressed (x, y, button)
   input_manager:mousepressed (x, y, button)
end

function love.mousereleased (x, y, button)
   input_manager:mousereleased (x, y, button)
end

local test = false
function love.keypressed (key, scancode, isrepeat)
   input_manager:keypressed (key, scancode, isrepeat)

   -- DEBUG:
   if key == 'f12' then test = not test end
end

function love.keyreleased (key, scancode)
   input_manager:keyreleased (key, scancode)
end

function love.update (dt)
   
   -- exec actions
   action_manager:update()   
      
   -- send stuff
   network_manager:update_server()

   -- receive stuff
   network_manager:receive()

   -- update entities
   entity_manager:update (dt)
   
end

function love.draw () 
   lg.print ("FPS: "  .. lt.getFPS(), 10, 10)
   lg.print ("Step: " .. network_manager.current_step, 10, 22)
   lg.print ("Time: " .. network_manager.elapsed_time, 10, 34)

   entity_manager:draw()
end
