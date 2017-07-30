local packer = {}

function packer.print_table (t, ind)
    local ind = ind or ""

    for k, v in pairs(t) do
        print(ind .. k, v)
        if(type(v) == 'table') then
            packer.print_table(v, ind.."\t")
        end
    end
end

-- NOTE: shallow
function packer.table_size (t)
   local c = 0

   for _, _ in pairs(t) do
      c = c+1
   end

   return c
end

-- NOTE: http://lua-users.org/wiki/CopyTable
function packer.copy (orig)
   local orig_type = type(orig)
   local copy
   if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
	 copy[packer.copy(orig_key)] = packer.copy(orig_value)
      end
      setmetatable(copy, packer.copy(getmetatable(orig)))
   else -- number, string, boolean, etc
      copy = orig
   end
   return copy
end

-- NOTE: this does not support metatable recursion

-- transforms table to string in 
-- key:value;key:value;...
-- format
function packer.to_string (tab)
    local output = ""
    
    for k, v in pairs (tab) do
        if type(v) == "table" then
            output = output .. tostring(k) .. ":(" .. packer.to_string(v) .. ");"
        else
            output = output .. tostring(k) .. ":" .. tostring(v) .. ";";
        end
    end

    return output
end

-- transforms string to array integer indices
-- PRECONDITION: input was an actual array, otherwise this will fail
-- TODO: inner tables like to_table
function packer.to_array (str)
   local pair_match  = "[%d]*:[%a%d%s%.%-_]*"
   local key_match   = "[%d]*"
   local value_match = ":[%a%d%s%.%-_]*"

   local output = {}
   
   for pair in str:gmatch (pair_match) do
      local k = pair:match (key_match)
      local v = pair:match (value_match)

      k = tonumber(k)

      if not k then
	 error ("packer/to_array: trying to convert non-array!")
      end
      
      if #v > 1 then v = v:sub(2)
      else           v = ''
      end

      output[k] = v
   end

   return output
end

-- transforms a stringified table back to a table
-- though all values will now be strings
-- TODO: DOCUMENTATION (this will not make sense anymore in a few days)
function packer.to_table (str) 
    local output = {}

    -- matches recursive tables in strings ( k:(..) )
    local inner_table_pair_match = "[%a%d%._]*:%b()"

    -- matches the actual inner table ( (..) ) (: & () need to be cut)
    local inner_table_value_match = ":%([%(%)%.%-%a%d%s:;_]*%)"

    -- matches (leftover) pairs ( k:v )
    local pair_match = "[%a%d%._]*:[%a%d%s%.%-_]*"

    -- matches key of a pair
    local key_match = "^[%a%d%._]*"

    -- matches value of a pair (: needs to be cut)
    local value_match = ":[%.%-%a%d%s_]*"

    for pair in str:gmatch(inner_table_pair_match) do
        local key = pair:match(key_match)
        local inner_table = pair:match(inner_table_value_match)

        if #inner_table > 2 then inner_table = inner_table:sub(3, -2)
        else                     inner_table = ""
        end

        --print(pair, key, inner_table)
        output[key] = packer.to_table(inner_table)
    end

    str = str:gsub(inner_table_pair_match, "")

    for pair in str:gmatch(pair_match) do
        if pair == "" then
            goto cont
        end

        local k = pair:match(key_match)
        local v = pair:match(value_match)

        if #v > 1 then v = v:sub(2) 
        else           v = ""
        end

        output[k] = v

        ::cont::
    end

    return output
end

function packer.to_bool (x)
    if x == 'true' then return true end
    if x == 'false' then return false end
    
    return not not x
end

-- testing
-- test_table = {x = "blargh", y = {a = {u = "ice"}, b = "berg"}, z = {xx = true}}
-- test_table_str = packer.to_string(test_table)
-- test_table_back = packer.to_table(test_table_str)
-- print(test_table_str)
-- --print(test_table_back.x, test_table_back.y.a, test_table_back.z.xx)

-- print ("-- OUTPUT")
-- print_table (test_table_back)

-- test_array = {1, 2, 3, 4}
-- test_array[2] = nil
-- packer.print_table(packer.to_array(packer.to_string(test_array)))

return packer
