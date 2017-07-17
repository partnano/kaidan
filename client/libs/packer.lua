local packer = {}

-- transforms table to string in 
-- key:value;key:value;...
-- format
function packer.to_string (table)
    local output = ""

    for k, v in pairs(table) do
        if type(v) == "table" then
            print("packer.lua: Nested tables not supported in to_string().")
            return ""
        else
            output = output .. tostring(k) .. ":" .. tostring(v) .. ";";
        end
    end

    return output
end

-- transforms a stringified table back to a table
-- though all values will now be strings
function packer.to_table (str) 
    local output = {}

    for pair in str:gmatch("[%a%d%s:%.%-]*") do
        if pair == "" then
            goto cont
        end

        local k = pair:match("[%a%d]*")
        local v = pair:match(":[%.%-%a%d%s]*")

        if #v > 1 then v = v:sub(2) end

        output[k] = v

        ::cont::
    end

    return output
end

-- testing
-- test_table = {x = "blargh", y = nil, z = true}
-- test_table_str = packer.to_string(test_table)
-- test_table_back = packer.to_table(test_table_str)
-- print(test_table_str)
-- print(test_table_back.x, test_table_back.y, test_table_back.z)


return packer