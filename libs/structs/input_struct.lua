local InputStruct = {

    serial = 0,
    send_time = 0,

    selected_entities = {},
    cmd = '',
    pos = {x = -1, y = -1}

}

function InputStruct:new (o)
    o = o or {}
    setmetatable( o, self)
    self.__index = self

    return o
end

return InputStruct