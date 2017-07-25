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

-- NOTE: this does not support metatable recursion

-- transforms table to string in 
-- key:value;key:value;...
-- format
function packer.to_string (tab)
    local output = ""
    
    for k, v in pairs(tab) do
        if type(v) == "table" then
            output = output .. tostring(k) .. ":(" .. packer.to_string(v) .. ");"
        else
            output = output .. tostring(k) .. ":" .. tostring(v) .. ";";
        end
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

return packer
