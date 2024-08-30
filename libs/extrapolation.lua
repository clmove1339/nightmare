local entity_manager = require 'libs.entity_manager';

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

return extrapolation;
