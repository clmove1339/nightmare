local memory = require 'libs.memory';

local utils = {}; do
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
    ---@return number
    function utils:play_sound(sound, volume, pitch, flags, delay)
        volume = volume or 1;
        pitch = pitch or 100;
        flags = flags or 0;
        delay = delay or 0;

        return IEngineSound:EmitAmbientSound(sound, 1., pitch, flags, delay);
    end;

    ---@param guid number
    ---@param force_sync? boolean
    function utils:stop_sound(guid, force_sync)
        IEngineSound:StopSoundByGuid(guid, force_sync or false);
    end;
end;

return utils;
