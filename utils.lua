local memory = require 'memory';

local utils = {}; do
    ---@private
    local ISurface = memory:interface('vguimatsurface', 'VGUI_Surface031', {
        SurfaceGetCursorPos = { 100, 'unsigned int(__thiscall*)(void *thisptr, int &x, int &y)' }
    });

    local IEngineSound = memory:interface('engine.dll', 'IEngineSoundClient003', {
        EmitAmbientSound = { 12, 'int(__thiscall*)(void*, const char*, float, int, int, float)' },
        StopSoundByGuid = { 17, 'int(__thiscall*)(void*, int, bool)' },
    });

    ---@public
    function utils:get_cursor_position()
        local x, y = ffi.new('int[1]'), ffi.new('int[1]');

        ISurface:SurfaceGetCursorPos(x, y);

        return vec2_t.new(x[0], y[0]);
    end;

    ---@param sound string
    ---@param volume? number
    ---@param pitch? number
    ---@param flags? number
    ---@param delay? number
    ---@return unknown
    function utils:play_sound(sound, volume, pitch, flags, delay)
        volume = volume or 1;
        pitch = pitch or 100;
        flags = flags or 0;
        delay = delay or 0;

        return IEngineSound:EmitAmbientSound(sound, 1., pitch, flags, delay);
    end;

    ---@param guid number
    ---@param force_sync? boolean
    ---@return unknown
    function utils:stop_sound(guid, force_sync)
        return IEngineSound:StopSoundByGuid(guid, force_sync or false);
    end;
end;

return utils;
