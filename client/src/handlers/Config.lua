local lm = love.mouse

local ConfigHandler = {
   input = {
      confined = true,
      scrollspeed = {
	 mouse = 50,
	 keyboard = 50
      }
   }
}

function ConfigHandler:load ()
   lm.setGrabbed (self.input.confined)
end

return ConfigHandler
