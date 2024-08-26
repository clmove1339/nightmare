require 'libs.enums';

local defensive = {}; do
    defensive.ticks = 0;
    defensive.max_ticks = 0;

    local max_tickbase = 0;
    register_callback('create_move', function(cmd)
        local me = entitylist.get_local_player();

        if me == nil then
            return;
        end;

        local tickbase = ffi.cast('int*', me[netvars.m_nTickBase])[0];

        if math.abs(tickbase - max_tickbase) > 64 then
            max_tickbase = 0;
        end;

        local defensive_ticks_left = 0;

        if tickbase > max_tickbase then
            max_tickbase = tickbase;
        elseif max_tickbase > tickbase then
            defensive_ticks_left = math.min(14, math.max(0, max_tickbase - tickbase - 1));
        end;

        defensive.ticks = defensive_ticks_left;
        defensive.max_ticks = math.max(defensive.max_ticks, defensive.ticks);
    end);

    function defensive:is_active()
        return self.ticks > 0;
    end;
end;

return defensive;
