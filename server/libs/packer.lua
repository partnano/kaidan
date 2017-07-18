local packer = {}

local function print_table (t, ind)
    local ind = ind or ""

    for k, v in pairs(t) do
        print(ind .. k, v)
        if(type(v) == 'table') then
            print_table(v, ind.."\t")
        end
    end
end

-- transforms table to string in 
-- key:value;key:value;...
-- format
function packer.to_string (table)
    local output = ""

    for k, v in pairs(table) do
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

    for pair in str:gmatch("[%a%d]*:%b()") do
        local key = pair:match("^[%a%d]*")
        local inner_table = pair:match(":%([%(%)%.%-%a%d%s:;]*%)")

        if #inner_table > 2 then inner_table = inner_table:sub(3, -2)
        else                     inner_table = ""
        end

        --print(pair, key, inner_table)
        output[key] = packer.to_table(inner_table)
    end

    str = str:gsub("[%a%d]*:%b()", "")

    for pair in str:gmatch("[%a%d%s:%.%-]*") do
        if pair == "" then
            goto cont
        end

        local k = pair:match("[%a%d]*")
        local v = pair:match(":[%.%-%a%d%s]*")

        if #v > 1 then v = v:sub(2) 
        else           v = ""
        end

        output[k] = v

        ::cont::
    end

    return output
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