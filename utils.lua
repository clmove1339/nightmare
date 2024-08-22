local memory = require 'memory';

local utils = {}; do
    ---@private
    local surface = memory:interface('vguimatsurface', 'VGUI_Surface031', {
        get_cursor_pos = { 100, 'unsigned int(__thiscall*)(void *thisptr, int &x, int &y)' }
    });

    local sound_client = memory:interface('engine.dll', 'IEngineSoundClient003', {
        emit_ambient_sound = { 12, 'int(__thiscall*)(void*, const char*, float, int, int, float)' },
        stop_sound_by_guid = { 17, 'int(__thiscall*)(void*, int, bool)' },
    });

    ---@public
    function utils:get_cursor_position()
        local x, y = ffi.new('int[1]'), ffi.new('int[1]');

        surface:get_cursor_pos(x, y);

        return vec2_t.new(x[0], y[0]);
    end;

    function utils:play_sound(sound, volume, pitch, flags, delay)
        volume = volume or 1;
        pitch = pitch or 100;
        flags = flags or 0;
        delay = delay or 0;

        return sound_client:emit_ambient_sound(sound, 1., pitch, flags, delay);
    end;

    function utils:stop_sound(guid, b)
        return sound_client:stop_sound_by_guid(guid, b or false);
    end;
end;

return utils;
