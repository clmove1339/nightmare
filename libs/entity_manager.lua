local engine_client = require 'libs.engine_client';
---@protected
---@class tick_data
---@field abs vec3_t
---@field vel vec3_t
---@field min vec3_t
---@field max vec3_t
---@field m_flSimulationTime number
---@field lag_time number
---@field defensive_ticks number

local entity_manager = {
    ---@type { [number]: { [number]: tick_data } }
    data = {},
}; do
    entity_manager.init = function(server_side)
        local players = entitylist.get_players(true);
        if #players == 0 then
            entity_manager.data = {};
            return;
        end;

        local tickcount = globals.tick_count;
        local me = entitylist.get_local_player();
        local my_index = me:get_index();

        entity_manager.data[tickcount] = {};

        local prev_tick = entity_manager.data[tickcount - 1];

        for i = 1, #players do
            local player = players[i];
            if (player and player:is_alive()) then
                local index = player:get_index();
                local ptr = player:get_address();

                local m_flSimulationTime = ffi.cast('float*', ptr + 0x268)[0];
                local m_flOldSimulationTime = ffi.cast('float*', ptr + 0x26C)[0];

                local prev_data = prev_tick and prev_tick[index];

                local lag_time = prev_data and prev_data.lag_time or 0;
                local last_defensive = prev_data and prev_data.defensive_ticks or 0;

                local is_lagged = m_flOldSimulationTime == m_flSimulationTime;
                local defensive_ticks = m_flOldSimulationTime - m_flSimulationTime;

                if index == my_index then
                    local net_channel = engine_client:get_net_channel_info();
                    if net_channel then
                        local ping = net_channel:get_latency(0) + net_channel:get_latency(1);

                        defensive_ticks = defensive_ticks - ping;
                    end;
                end;

                defensive_ticks = to_ticks(defensive_ticks);

                lag_time = is_lagged and lag_time + 1 or 0;

                local abs = player:get_origin();
                local vel = player:get_velocity();

                local min = ffi.cast('vector_t*', player[netvars.m_vecMins])[0];
                local max = ffi.cast('vector_t*', player[netvars.m_vecMaxs])[0];

                min = vec3_t.new(min.x, min.y, min.z);
                max = vec3_t.new(max.x, max.y, max.z);

                if index == my_index and lag_time ~= 0 and server_side then
                    for i = 1, 64 do
                        local lp_prev_tick = entity_manager.data[tickcount - i];
                        if not lp_prev_tick then
                            break;
                        end;

                        local lp_prev_data = lp_prev_tick[my_index];
                        if not lp_prev_data then
                            break;
                        end;

                        if lp_prev_data.lag_time == 0 then
                            abs, vel, min, max = lp_prev_data.abs, lp_prev_data.vel, lp_prev_data.min, lp_prev_data.max;
                            break;
                        end;
                    end;
                end;

                entity_manager.data[tickcount][index] = {
                    abs = vec3_t.new(abs.x, abs.y, abs.z),
                    vel = vec3_t.new(vel.x, vel.y, vel.z),
                    min = min,
                    max = max,
                    m_flSimulationTime = m_flSimulationTime,
                    lag_time = lag_time,
                    defensive_ticks = defensive_ticks > 0 and defensive_ticks or last_defensive - 1
                };
            end;
        end;

        for tick, _ in ipairs(entity_manager.data) do
            if math.abs(tickcount - tick) > 64 then
                table.remove(entity_manager.data, tick);
            end;
        end;
    end;

    ---@param tick number
    ---@param player entity_t
    ---@return tick_data?
    entity_manager.get = function(tick, player)
        local data = entity_manager.data[tick];
        if not data then
            return;
        end;

        data = data[player:get_index()];
        if not data then
            return;
        end;

        return data;
    end;
end;

register_callback('create_move', function()
    xpcall(entity_manager.init, print, true);
end);

return entity_manager;
