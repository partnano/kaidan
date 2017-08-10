-- globals
lg = love.graphics
lt = love.timer

client_id = nil

-- general libs
packer = require 'libs.packer'

-- handlers - public, intended to be used by the whole program
Handlers = {
   Input       = require 'src.handlers.Input',
   Action      = require 'src.handlers.Action',
   Network     = require 'src.handlers.Network',
   Simulation  = require 'src.handlers.Simulation'
}

function love.load ()
   Handlers.Simulation:load()
   Handlers.Network:load()
end

function love.mousepressed (x, y, button)
   Handlers.Input:mousepressed (x, y, button)
end

function love.mousereleased (x, y, button)
   Handlers.Input:mousereleased (x, y, button)
end

local test = false
function love.keypressed (key, scancode, isrepeat)
   Handlers.Input:keypressed (key, scancode, isrepeat)

   -- DEBUG:
   if key == 'f12' then test = not test end
end

function love.keyreleased (key, scancode)
   Handlers.Input:keyreleased (key, scancode)
end

function love.update (dt)
   
   -- exec actions
   Handlers.Action:update()   
      
   -- send stuff
   Handlers.Network:update_server()

   -- receive stuff
   Handlers.Network:receive()

   -- update entities
   Handlers.Simulation:update (dt, Handlers.Network.step_dt)
   
end

function love.draw () 
   lg.print ("FPS: "  .. lt.getFPS(), 10, 10)
   lg.print ("Step: " .. Handlers.Network.current_step, 10, 22)
   lg.print ("Time: " .. Handlers.Network.elapsed_time, 10, 34)

   Handlers.Simulation:draw()
end
