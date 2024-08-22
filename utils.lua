local memory = require 'memory';

local utils = {}; do
    ---@private
    local get_cursor_pos = memory:get_vfunc('vguimatsurface.dll', 'VGUI_Surface031', 100, 'unsigned int(__thiscall*)(void *thisptr, int &x, int &y)');
    ---@public
    function utils:get_cursor_position()
        local x, y = ffi.new('int[1]'), ffi.new('int[1]');

        get_cursor_pos(x, y);

        return vec2_t.new(x[0], y[0]);
    end;
end;

return utils;
