local Input = {

   packet_type = 'input',
   client_id = -1,
   serial = 0,
   exec_time = 0,
   exec_step = 0,
   rand = 0,

   selected_entities = {},
   cmd = '',
   pos = {x = -1, y = -1}

}

function Input:copy()
   -- NOTE: shallow copy (for now)
   local copy = {}

   for k, v in pairs(self) do
      copy[k] = v
   end

   return copy
end

return Input
