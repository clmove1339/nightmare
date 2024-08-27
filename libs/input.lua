local ffi = require 'ffi';

local input = {}; do
    local keys = {};

    function input:is_key_pressed(key)
        local result = ffi.C.GetKeyState(key);
        return result ~= 0 and bit.band(result, 0x8000) ~= 0;
    end;

    function input:is_key_clicked(code)
        local state = self:is_key_pressed(code);

        if keys[code] == nil then
            keys[code] = false;
        end;

        if not state then
            keys[code] = false;
            return false;
        end;

        if not keys[code] then
            keys[code] = true;
            return true;
        end;

        return false;
    end;
end;

return input;
