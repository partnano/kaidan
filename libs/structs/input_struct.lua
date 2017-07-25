local Input = {

   packet_type = 'input',
   client_id = -1,
   serial = 0,
   exec_time = 0,

   selected_entities = {},
   cmd = '',
   pos = {x = -1, y = -1}

}

function Input:new (o)
   o = o or {}
   setmetatable( o, self )
   self.__index = self

   return o
end

return Input
