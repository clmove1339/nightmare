local exploit = require 'libs.exploit';

local entity_manager = { data = {} }; do
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

                local prev_data = prev_tick and prev_tick[index] or nil;
                local lag_time = prev_data and prev_data.lag_time or 0;

                local is_lagged = m_flOldSimulationTime >= m_flSimulationTime;

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
                            goto brk;
                        end;

                        local lp_prev_data = lp_prev_tick[my_index];
                        if not lp_prev_data then
                            goto brk;
                        end;

                        if lp_prev_data.lag_time == 0 then
                            abs, vel, min, max = lp_prev_data.abs, lp_prev_data.vel, lp_prev_data.min, lp_prev_data.max;
                            goto brk;
                        end;
                    end;

                    ::brk::
                end;

                entity_manager.data[tickcount][index] = {
                    abs = vec3_t.new(abs.x, abs.y, abs.z),
                    vel = vec3_t.new(vel.x, vel.y, vel.z),
                    min = min,
                    max = max,
                    m_flSimulationTime = m_flSimulationTime,
                    lag_time = lag_time,
                };
            end;
        end;

        for tick, _ in ipairs(entity_manager.data) do
            if math.abs(tickcount - tick) > 64 then
                table.remove(entity_manager.data, tick);
            end;
        end;
    end;
end;

local function is_standing(ent, abs, min, max)
    min = min + abs;
    max = max + abs;

    local collisions = {
        { vec3_t.new(min.x, min.y, min.z - 2), vec3_t.new(max.x, max.y, min.z - 2) },
        { vec3_t.new(min.x, max.y, min.z - 2), vec3_t.new(max.x, min.y, min.z - 2) }
    };

    for i = 1, #collisions do
        local pos = collisions[i];
        local tracer = engine.trace_line(pos[1], pos[2], ent, 0xFFFFFFFF);

        local real_dist = math.floor(pos[2]:dist(pos[1]));
        local dist = math.floor(tracer.end_pos:dist(pos[1]));

        if dist < real_dist then
            return true, min.z;
        end;
    end;

    return false;
end;

local extrapolation = {}; do
    ---@param ent entity_t
    ---@param ticks number?
    ---@return vec3_t?
    extrapolation.get = function(ent, ticks)
        if not (ent and ent:is_alive()) then
            return;
        end;

        local tickcount = globals.tick_count;
        local index = ent:get_index();

        local tick_data = entity_manager.data[tickcount - 1];

        if not tick_data then
            return;
        end;

        local data = tick_data[index];

        if not data then
            return;
        end;

        if not ticks then
            ticks = data.lag_time;
        end;

        if ticks < 1 then
            return ent:get_origin();
        end;

        local interval = globals.interval_per_tick;
        local sv_gravity = cvars['sv_gravity']:get_float() * interval;

        local min, max, abs, vel = data.min, data.max, data.abs, data.vel;
        local sim = { abs = abs, vel = vel };

        for i = 1, ticks do
            local standing, stand_height = is_standing(ent, sim.abs, min, max);

            if not standing then
                sim.vel.z = math.clamp(sim.vel.z - sv_gravity, -320, 320);
            else
                sim.abs.z = stand_height;
                sim.vel.z = 0;
            end;

            sim.abs = sim.abs + (sim.vel * interval);
        end;

        return sim.abs;
    end;
end;

register_callback('create_move', function()
    xpcall(entity_manager.init, print, true);
end);

return extrapolation;
