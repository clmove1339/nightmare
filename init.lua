--#region: Pre load
local LOAD_TIME = os.clock();
math.randomseed(os.time());
--#endregion

--#region: package.path

do
    local get_csgo_folder = function()
        local source = debug.getinfo(1, 'S').source:sub(2, -1);
        return source:match('^(.-)nix/') or source:match('^(.-)lua\\');
    end;

    local csgo_folder = get_csgo_folder();
    package.path = package.path .. string.format('%slua\\nightmare\\?.lua;', csgo_folder);
    package.path = package.path .. string.format('%slua\\nightmare\\?\\init.lua;', csgo_folder);
end;

--#endregion

--#region: Libraries

require 'libs.enums';
require 'libs.global';
require 'libs.interfaces';
require 'libs.entity';
require 'libs.vector';
require 'libs.color';
require 'libs.render';
require 'libs.vector';

local engine_client = require 'libs.engine_client';
local materials = require 'libs.material_system';
local animation = require 'libs.animation';
local exploit = require 'libs.exploit';
local inspect = require 'libs.inspect';
local timers = require 'libs.timers';
local memory = require 'libs.memory';
local utils = require 'libs.utils';
local vmt = require 'libs.vmt';
local ui = require 'libs.ui';
local input = require 'libs.input';
local convar_manager = require 'libs.convar_manager';
local extrapolation = require 'libs.extrapolation';

local font = {
    icons = {
        -- [16] = render.setup_font('nix/fonts/nightmare.ttf', 16)
        [16] = render.setup_font('c:/windows/fonts/seguisb.ttf', 16)
    },
    text = {
        [18] = render.setup_font('c:/windows/fonts/seguisb.ttf', 18, 32)
    }
};

--#endregion

--#region: Main

local aimbot = {}; do
    ---@private
    local handle = ui.create('Aimbot');

    aimbot.jump_scout = { state = false }; do
        -- чешем яйца
        local group, enable = handle:switch('Jump scout', nil, true);

        local auto_stop = group:switch('Auto stop', true, false);
        local hitchance = group:slider_int('Hit chance', 0, 100, 55);
        local min_damage = group:slider_int('Min damage', 1, 120, nixware['Ragebot']['Target']['Scout'].min_damage:get());
        local on_top = group:switch('Stop on top', false);

        auto_stop:connect({
            hitchance,
            min_damage,
            on_top,
        }, true);

        function aimbot.jump_scout:threat_hittable()
            local me = entitylist.get_local_player();

            if not me then
                return false;
            end;

            local my_origin = me:get_origin();

            local entities = entitylist.get_entities('CCSPlayer', false);

            for i = 1, #entities do
                local player = entities[i];
                if player and player:is_alive() then
                    local can_hit = ffi.cast('int*', player[netvars.m_bGunGameImmunity])[0] == 0;

                    if not player:is_spectator() and player:is_enemy() and player:is_visible(me) and can_hit then
                        local distance = my_origin:dist(player:get_origin());

                        if distance <= 800 + (hitchance:get() * 2) then -- как это вообще должно работать
                            return true;
                        end;
                    end;
                end;
            end;

            return false;
        end;

        function aimbot.jump_scout:stop(cmd)
            local me = entitylist.get_local_player();

            if me == nil then
                return;
            end;

            local velocity = me:get_velocity();
            local direction = velocity:to_angle();
            local speed = velocity:length2d();

            if speed <= 15 then
                return;
            end;

            direction.yaw = normalize_yaw(cmd.viewangles.yaw - direction.yaw);

            local negated_direction = direction:forward() * -speed;

            cmd.forwardmove = negated_direction.x;
            cmd.sidemove = negated_direction.y;
        end;

        function aimbot.jump_scout:on_create_move(cmd)
            local me = entitylist.get_local_player();
            local velocity = me:get_velocity();

            if not (me and me:is_alive()) then
                return;
            end;

            local weapon = me:get_active_weapon();
            if not weapon then
                return;
            end;

            if not weapon:get_class_name():find('SSG08') then
                return;
            end;

            local flags = ffi.cast('int*', me[netvars.m_fFlags])[0];
            local in_air = bit.has(cmd.buttons, IN.JUMP) or bit.hasnt(flags, FL.ONGROUND);

            local active = enable:get() and self:threat_hittable() and me:can_fire() and in_air;

            if input:is_key_pressed(0x20) then
                if not on_top:get() or math.abs(velocity.z) > 10 or velocity.z == 0 then
                    active = false;
                end;
            end;

            aimbot.jump_scout.state = active;

            if active then
                local scout = nixware['Ragebot']['Target']['Scout'];

                scout.min_damage:override(min_damage:get());
                scout.hit_chance:override(hitchance:get());

                if auto_stop:get() then
                    nixware['Movement']['Movement'].auto_strafer:override(false);
                    scout.auto_stop:override(false);
                    self:stop(cmd);
                end;
            end;
        end;

        register_callback('create_move', function(cmd)
            xpcall(aimbot.jump_scout.on_create_move, print, aimbot.jump_scout, cmd);
        end);
    end;

    aimbot.indicator = {
        state = 'Chilling',
        postfix = '',
        think_time = 0,
        next_think_time = 5,
    }; do
        local enable = handle:switch('Enable aimbot indicator', false);

        local old_text = '';

        local colors = {
            background = color_t.new(.1, .1, .1, 0.8),
            upper_left = color_t.new(1, 0.4, 0.4, 0.6),
            upper_right = color_t.new(0.4, 1, 0.4, 0.6),
            bottom_right = color_t.new(0.4, 0.4, 1, 0.6),
            bottom_left = color_t.new(1, 1, 0.4, 0.6)
        };

        local base_colors = {
            color_t.new(1, 0.4, 0.4, 0.6),
            color_t.new(0.4, 1, 0.4, 0.6),
            color_t.new(0.4, 0.4, 1, 0.6),
            color_t.new(1, 1, 0.4, 0.6)
        };

        previous_phase = 1;

        function aimbot.indicator:get_best_target()
            local me = entitylist.get_local_player();
            if not (me and me:is_alive()) then
                return;
            end;

            local players = entitylist.get_players(true, true, true);
            if #players == 0 then
                return;
            end;

            local best = {
                distance = math.huge,
                is_visible = false,
                entity = nil
            };

            local my_origin = me:get_origin();

            for _, player in pairs(players) do
                local is_visible = player:is_visible(me);
                local origin = player:get_origin();
                local distance = origin:dist(my_origin);

                if is_visible then
                    if distance < best.distance then
                        best.distance = distance;
                        best.is_visible = true;
                        best.entity = player;
                    end;
                else
                    if not best.is_visible and distance < best.distance then
                        best.distance = distance;
                        best.entity = player;
                    end;
                end;
            end;

            return best;
        end;

        function aimbot.indicator:update_state(best)
            local dt = globals.frame_time;
            local is_visible = best and best.is_visible;

            aimbot.indicator.think_time = aimbot.indicator.think_time - dt;

            if aimbot.indicator.think_time > 0 and not is_visible then
                aimbot.indicator.state = 'Thinking';
                aimbot.indicator.next_think_time = math.random(1, 5);
                goto escape;
            end;

            if aimbot.indicator.think_time < 0 then
                local brainless_time = math.abs(aimbot.indicator.think_time);

                if brainless_time > aimbot.indicator.next_think_time then
                    aimbot.indicator.think_time = 1 + math.random() * 2;
                end;
            end;

            if not best then
                aimbot.indicator.state = 'Chilling';
                goto escape;
            end;

            if is_visible then
                aimbot.indicator.state = 'Peeking';
                goto escape;
            end;

            ::escape::
            return aimbot.indicator.state;
        end;

        function aimbot.indicator:animate()
            local phase = math.floor(globals.frame_count % 128 / 32) + 1;
            local phases = {
                phase,
                (phase % 4) + 1,
                (phase + 1) % 4 + 1,
                (phase + 2) % 4 + 1
            };

            colors.upper_left = colors.upper_left:lerp(base_colors[phases[1]], 0.1);
            colors.upper_right = colors.upper_right:lerp(base_colors[phases[2]], 0.1);
            colors.bottom_right = colors.bottom_right:lerp(base_colors[phases[3]], 0.1);
            colors.bottom_left = colors.bottom_left:lerp(base_colors[phases[4]], 0.1);

            if previous_phase == 4 and phase == 1 then
                for i = 1, #base_colors do
                    base_colors[i] = color_t.new(math.random(), math.random(), math.random(), math.random());
                end;
            end;

            previous_phase = phase;
        end;

        function aimbot.indicator:draw()
            if not enable:get() then
                return;
            end;

            local me = entitylist.get_local_player();
            if not (me and me:is_alive()) then
                return;
            end;

            aimbot.indicator:animate();

            local best = aimbot.indicator:get_best_target();
            local state = aimbot.indicator:update_state(best);

            local static_text = 'State: ' .. state .. aimbot.indicator.postfix;
            local dynamic_text;

            if best then
                local player_info = best.entity:get_player_info();
                dynamic_text = string.format('Target: %s\nDistance: %.1f', player_info.name, best.distance);
            end;

            ---@diagnostic disable-next-line: cast-local-type
            local static_text_size = render.measure_text(font.text[18], static_text);
            local dynamic_text_size = vec2_t.new(0, 0);

            if dynamic_text then
                dynamic_text_size = render.measure_text(font.text[18], dynamic_text);
            end;

            local text_size = static_text_size + dynamic_text_size;

            local width = animation:new('@aimbot.indicator.width', 0, math.max(200, static_text_size.x, dynamic_text_size.x), 0.1);
            local height = animation:new('@aimbot.indicator.height', 0, math.max(10, text_size.y + 10), 0.1);
            local fade = animation:new('@aimbot.indicator.fade', 0, best and 1 or 0, 0.1);
            local alpha = fade * 255;

            local size = vec2_t.new(width, height);
            local padding = vec2_t.new(5, 5);
            local min = vec2_t.new(10, screen.y * 0.5);
            local max = min + size;

            for i = 1, 10 do
                local weight = math.exp(-5 * i / 10);

                render.rect_filled_fade(
                    min - i, max + i,
                    colors.upper_left:alpha_modulatef(weight),
                    colors.upper_right:alpha_modulatef(weight),
                    colors.bottom_right:alpha_modulatef(weight),
                    colors.bottom_left:alpha_modulatef(weight)
                );
            end;

            render.push_clip_rect(min, max);

            render.rect_filled(min, max, colors.background, 5);
            render.text(font.text[18], min + padding, color_t.new(1, 1, 1, 1), '', static_text);

            if dynamic_text then
                old_text = dynamic_text;
            end;

            if dynamic_text or alpha > 1 then
                local offset = vec2_t.new(0, static_text_size.y);
                render.text(font.text[18], min + padding + offset, color_t.new(1, 1, 1, fade), '', old_text);
            end;

            render.pop_clip_rect();
        end;

        register_callback('paint', function()
            xpcall(aimbot.indicator.draw, print, aimbot.indicator);
        end);
    end;

    local logs = {}; do
        local group, enable = handle:switch('Aimbot notifications', false, true);
        local output = group:multicombo('Output', { 'Hits', 'Misses' }, { 0, 1 });

        local hitgroups = {
            [0]  = 'generic',
            [1]  = 'head',
            [2]  = 'chest',
            [3]  = 'stomach',
            [4]  = 'left arm',
            [5]  = 'right arm',
            [6]  = 'left leg',
            [7]  = 'right leg',
            [8]  = 'neck',
            [10] = 'gear'
        };

        local type_hit = {
            ['inferno'] = 'Burned',
            ['taser'] = 'Tasered',
            ['knife'] = 'Knifed',
            ['hegrenade'] = 'Naded',
            ['decoy'] = 'Naded',
            ['flashbang'] = 'Naded',
            ['smokegrenade'] = 'Naded',
            ['molotov'] = 'Naded'
        };

        local map = {};
        local last_update = 0;

        function logs.on_weapon_fire(event)
            local userid = entitylist.get(event:get_int('userid', 0), true);
            local me = entitylist.get_local_player();

            if me ~= userid then
                return;
            end;

            local weapon = me:get_active_weapon();
            local class = weapon:get_class_name();

            last_update = globals.cur_time;

            map[last_update] = {
                state = 'shot',
                left_mouse = input:is_key_clicked(0x01) or input:is_key_pressed(0x01),
                right_mouse = input:is_key_clicked(0x02) or input:is_key_pressed(0x02), -- НА ВСЯКИЙ СЛУЧАЙ
                is_grenade = class:find('Grenade')
            };
        end;

        function logs.on_aimbot_hit(event)
            if not enable:get() or not output:get(0) then
                return;
            end;

            if map[last_update].state == 'shot' then
                map[last_update].state = 'hit';
            end;

            local userid = entitylist.get(event:get_int('userid', 0), true);
            local attacker = entitylist.get(event:get_int('attacker', 0), true);

            local me = entitylist.get_local_player();

            if me == nil or userid == nil or attacker == nil then
                return;
            end;

            if attacker ~= me or me == userid then
                return;
            end;

            local player_info = userid:get_player_info();
            local weapon = event:get_string('weapon', 'unknown');
            local hit = type_hit[weapon] or 'Hit';

            if hit == 'Hit' then
                print(string.format("%s %s's %s for %s damage", hit, player_info.name, hitgroups[event:get_int('hitgroup', 0)], event:get_int('dmg_health', 0)));
            else
                print(string.format('%s %s for %s damage', hit, player_info.name, event:get_int('dmg_health', 0)));
            end;
        end;

        function logs.on_aimbot_miss()
            if not enable:get() or not output:get(1) then
                return;
            end;

            local data = map[last_update];
            local state = data.state;

            if state == '' then
                return;
            end;

            if data.left_mouse or data.right_mouse or data.is_grenade then
                map[last_update].state = '';

                return;
            end;

            if state == 'shot' then
                local reason = '?';

                if aimbot.jump_scout.state then
                    reason = 'jump evaluation';
                end;

                print(string.format('Miss shot due to %s', reason));
            end;

            map[last_update].state = '';
        end;

        register_callback('weapon_fire', logs.on_weapon_fire);
        register_callback('player_hurt', logs.on_aimbot_hit);
        register_callback('paint', logs.on_aimbot_miss);
    end;
end;

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-aimbot');
    local enable = handle:switch('Enabled');
    local sub_handle = handle:combo('Anti-aimbot part:', { 'General', 'Settings' });

    enable:connect({
        sub_handle
    }, true);

    antiaim.general = {}; do
        local features = handle:multicombo('Features', { 'Anti-backstab', 'Manual anti-aim', 'Fast ladder' });

        local manual = {
            left = handle:keybind('Manual left'),
            right = handle:keybind('Manual right'),
            reset = handle:keybind('Manual reset'),
            static = handle:switch('Use static on manual'),
        };

        sub_handle:connect({
            master = features,
            [2] = manual
        }, 1);

        function antiaim:fast_ladder(cmd)
            if not features:get(2) then
                return;
            end;

            local me = entitylist.get_local_player();
            local m_MoveType = ffi.cast('int*', me[0x25C])[0];

            if m_MoveType == 9 then
                if cmd.forwardmove == 0 then
                    return;
                end;

                cmd.viewangles.yaw = engine.get_view_angles().yaw - 90;
                cmd.viewangles.pitch = 89;

                if cmd.forwardmove > 1 then
                    cmd.buttons = bit.band(cmd.buttons, bit.bor(cmd.buttons, IN.RIGHT));
                    cmd.buttons = bit.band(cmd.buttons, bit.bor(cmd.buttons, IN.BACK));
                    cmd.buttons = bit.band(cmd.buttons, IN.FORWARD);
                    cmd.buttons = bit.band(cmd.buttons, IN.LEFT);
                end;
                if cmd.forwardmove < -1 then
                    cmd.buttons = bit.band(cmd.buttons, bit.bor(cmd.buttons, IN.LEFT));
                    cmd.buttons = bit.band(cmd.buttons, bit.bor(cmd.buttons, IN.FORWARD));
                    cmd.buttons = bit.band(cmd.buttons, IN.BACK);
                    cmd.buttons = bit.band(cmd.buttons, IN.RIGHT);
                end;
            end;

            return;
        end;

        register_callback('create_move', function(cmd)
            -- xpcall(function()
            antiaim:fast_ladder(cmd);
            -- end, print);
        end);
    end;

    ---@alias PLAYER_STATE string
    ---| 'Default'
    ---| 'Standing'
    ---| 'Running'
    ---| 'Walking'
    ---| 'Crouching
    ---| 'Sneaking'
    ---| 'In Air'
    ---| 'In Air & Crouching'
    ---| 'On use'
    local states = { 'Default', 'Standing', 'Running', 'Walking', 'Crouching', 'Sneaking', 'In Air', 'In Air & Crouching', 'On use' };

    ---@param cmd user_cmd_t
    ---@return PLAYER_STATE
    function antiaim:get_statement(cmd)
        local me = entitylist.get_local_player();

        if not (me and me:is_alive()) then
            return states[1];
        end;

        local velocity = me:get_velocity();
        local flags = ffi.cast('int*', me[netvars.m_fFlags])[0];
        local duck_amount = ffi.cast('int*', me[netvars.m_flDuckAmount])[0];
        local speed = math.sqrt(velocity.x ^ 2 + velocity.y ^ 2);

        local in_crouch = duck_amount > 0;
        local in_air = bit.has(cmd.buttons, IN.JUMP) or bit.hasnt(flags, FL.ONGROUND);
        local in_speed = bit.has(cmd.buttons, IN.SPEED);
        local in_use = bit.has(cmd.buttons, IN.USE); -- ЕБУЧИЕ ФИКСИКИ СУКАААА input:is_key_pressed(0x45)

        if in_use then
            return states[9];
        end;

        if in_air then
            return states[in_crouch and 8 or 7];
        end;

        if in_crouch then
            return states[speed > 2 and 6 or 5];
        end;

        if speed > 2 then
            return states[in_speed and 4 or 3];
        end;

        return states[2];
    end;

    antiaim.builder = {}; do
        ---@type table<PLAYER_STATE, CState>
        local information = {};
        local state_selector = handle:combo('State', states, 0);

        enable:connect({
            master = sub_handle,
            [2] = state_selector
        }, true);

        ---@param state PLAYER_STATE
        ---@param index number
        local function setup_state(state, index)
            ---@class CState
            local info = {
                override = handle:switch('Override ' .. state, state == 'Default'),
                pitch = handle:combo('Pitch##' .. state, { 'Off', 'Down', 'Fake down', 'Fake up' }, 1),
                base_yaw = handle:combo('Base yaw##' .. state, { 'Local view', 'Static', 'At targets' }, 2),
                yaw_offset = handle:slider_int('Yaw offset##' .. state, -180, 180, 180),
                yaw_modifier = handle:combo('Yaw modifier##' .. state, { 'Off', 'Center', 'Offset', 'Random', '3-Way', '5-Way' }, 0),
                yaw_modifier_offset = handle:slider_int('Yaw modifier offset##' .. state, -180, 180, 0),
                yaw_desync = handle:combo('Yaw desync##' .. state, { 'Off', 'Static', 'Jitter', 'Random Jitter' }),
                yaw_desync_length = handle:slider_int('Yaw desync length##' .. state, 0, 60, 0),
                enable_fakelag = handle:switch('Enable fakelag##' .. state, false, false, 'Movement/Fakelag'),
                fakelag_type = handle:combo('Fakelag type##' .. state, { 'Off', 'Static', 'Fluctuation', 'Adaptive', 'Random', 'Allah', 'Fake peek' }, nil, 'Movement/Fakelag'),
                fakelag_limit = handle:slider_int('Fakelag limit##' .. state, 0, 16, 0, 'Movement/Fakelag'),
            };

            local defensive_class, defensive_switch = handle:switch('Defensive settings [  ]##' .. state, nil, true);

            info.defensive = defensive_switch;
            info.defensive_pitch = defensive_class:combo('Pitch##' .. state, { 'Off', 'Custom', 'Random', 'Jitter', 'RAKETA' });
            info.defensive_pitch_value = defensive_class:slider_int('Pitch value##' .. state, -89, 89, 0);
            info.defensive_yaw = defensive_class:combo('Yaw modifier##' .. state, { 'Off', 'Opposite', 'Spin', 'Random' });
            info.defensive_spin_speed = defensive_class:slider_int('Spin speed##' .. state, 0, 180, 0);

            state_selector:connect({
                master = info.override,
                info.pitch,
                info.base_yaw,
                info.yaw_offset,
                {
                    master = info.yaw_modifier,
                    yaw_modifier = info.yaw_modifier,
                    yaw_modifier_offset = info.yaw_modifier_offset,
                },
                {
                    master = info.yaw_desync,
                    yaw_desync_length = info.yaw_desync_length,
                },
                {
                    master = info.enable_fakelag,
                    {
                        master = info.fakelag_type,
                        fakelag_limit = info.fakelag_limit
                    }
                },
                info.defensive,
                {
                    master = info.defensive_pitch,
                    custom_defensive_pitch = info.defensive_pitch_value
                },
                {
                    master = info.defensive_yaw,
                    [3] = info.defensive_spin_speed
                }
            }, index);

            if state == 'Default' then
                info.override:depend({ false });
            end;

            information[state] = info;
        end;

        for i, state in ipairs(states) do
            setup_state(state, i);
        end;

        local source = nixware['Movement']['Anti aim'];

        local nixware_elements = {
            pitch = source.pitch,
            base_yaw = source.base_yaw,
            yaw_offset = source.yaw_offset,
            yaw_modifier = source.yaw_modifier,
            yaw_modifier_offset = source.yaw_modifier_offset,
            yaw_desync = source.yaw_desync,
            yaw_desync_length = source.yaw_desync_length,
        };

        antiaim.fakelag = {}; do
            local cache = {};
            local server_origin = vec3_t.new(0, 0, 0);

            ---@param state CState
            ---@param cmd user_cmd_t
            antiaim.fakelag.handle = function(state, cmd)
                local me = entitylist.get_local_player();
                if not me then
                    return;
                end;

                nixware['Movement']['Fakelag'].limit:set(0); -- Никсер соси мою сраку

                if not state.enable_fakelag:get() then
                    cmd.send_packet = true;
                    return;
                end;

                local type = state.fakelag_type:get();
                local limit = state.fakelag_limit:get();

                local choked = globals.choked_commands;
                local velocity = me:get_velocity();
                local speed = velocity:length2d();

                if type == 0 then
                    cmd.send_packet = true;
                elseif type == 1 then
                    cmd.send_packet = choked >= limit;
                elseif type == 2 then
                    if cache[1] then
                        local bSendPacket = choked >= math.floor(.5 + limit / 2);
                        cmd.send_packet = bSendPacket;
                        cache[1] = not bSendPacket;
                    else
                        local bSendPacket = choked >= limit;
                        cmd.send_packet = bSendPacket;
                        cache[1] = bSendPacket;
                    end;
                elseif type == 3 then
                    local speed_per_tick = speed * globals.interval_per_tick;
                    local lag_for_lc = math.floor(64 / speed_per_tick) + 2;

                    if lag_for_lc > 16 then
                        cmd.send_packet = choked >= limit;
                    else
                        cmd.send_packet = choked >= lag_for_lc;
                    end;
                elseif type == 4 then
                    if not cache[2] then
                        cache[2] = math.random(1, limit);
                    end;

                    local bSendPacket = choked >= cache[2];

                    cmd.send_packet = bSendPacket;

                    if bSendPacket then
                        cache[2] = math.random(1, limit);
                    end;
                elseif type == 5 then
                    if choked >= limit then
                        cmd.send_packet = true;
                    else
                        cmd.send_packet = math.abs(velocity.z) < 10;
                    end;
                elseif type == 6 then
                    local in_move = bit.band(cmd.buttons, IN.BACK + IN.FORWARD + IN.MOVELEFT + IN.MOVERIGHT) ~= 0;

                    if speed > 200 then
                        cmd.send_packet = in_move and choked >= math.floor(limit / 4) or choked >= limit;
                    else
                        cmd.send_packet = choked >= limit;
                    end;
                end;

                if cmd.send_packet then
                    local origin = me:get_origin();
                    local distance = origin:dist(server_origin);

                    if _DEV then
                        printf('lc: %s', distance > 64);
                        printf('distance: %.2f', distance);
                        printf('choked: %d\n', globals.choked_commands);
                    end;

                    server_origin = vec3_t.new(origin.x, origin.y, origin.z);
                end;
            end;
        end;

        antiaim.defensive = {}; do
            local cache = { false, 0 };
            -- 'Off', 'Custom', 'Random', 'Jitter', 'RAKETA'
            -- 'Off' 'Opposite', 'Spin', 'Random'

            ---@param settings CState
            ---@param type integer
            ---@return number
            antiaim.defensive.calculate_pitch = function(settings, type)
                local value = settings.defensive_pitch_value:get();

                if type == 1 then
                    return value;
                elseif type == 2 then
                    return math.random(-math.abs(value), math.abs(value));
                elseif type == 3 then
                    if globals.choked_commands == 0 then
                        cache[1] = not cache[1];
                    end;

                    return cache[1] and value or -value;
                end;
                return 0;
            end;

            ---@param settings CState
            ---@param type integer
            antiaim.defensive.calculate_yaw = function(settings, type)
                if type == 1 then
                    source.yaw_modifier:set(1);
                    source.yaw_modifier_offset:set(90);
                elseif type == 2 then
                    local spin_speed = settings.defensive_spin_speed:get();
                    if cache[2] > 180 then
                        cache[2] = -180;
                    end;
                    cache[2] = cache[2] + spin_speed;
                    source.base_yaw:set(0);
                    source.yaw_offset:set(cache[2]);
                elseif type == 3 then
                    source.base_yaw:set(0);
                    source.yaw_offset:set(math.random(-180, 180));
                end;
            end;

            ---@param settings CState
            ---@param cmd user_cmd_t
            antiaim.defensive.handle = function(settings, cmd)
                local me = entitylist.get_local_player();
                if not (me and me:is_alive()) then
                    return;
                end;

                if bit.has(cmd.buttons, IN.ATTACK) then
                    return;
                end;

                if not settings.defensive:get() then
                    return;
                end;

                if not exploit:is_break_lagcomp() then
                    return;
                end;

                local pitch_type = settings.defensive_pitch:get();
                local modifier_type = settings.defensive_yaw:get();
                local m_MoveType = ffi.cast('int*', me[0x25C])[0];

                if pitch_type ~= 0 and (m_MoveType ~= 8 or m_MoveType ~= 9) then
                    source.pitch:set(0);
                    cmd.viewangles.pitch = antiaim.defensive.calculate_pitch(settings, pitch_type);
                end;

                if modifier_type ~= 0 then
                    source.yaw_modifier:set(0);
                    antiaim.defensive.calculate_yaw(settings, modifier_type);
                end;
            end;
        end;

        antiaim.legit = { trigger = false }; do
            ---@param state PLAYER_STATE
            antiaim.legit.handle = function(state)
                local me = entitylist.get_local_player();
                local is_defusing = ffi.cast('int*', me[netvars.m_bIsDefusing])[0] == 1;
                local is_grabbing = ffi.cast('int*', me[netvars.m_bIsGrabbingHostage])[0] == 1;

                if is_defusing or is_grabbing then
                    if antiaim.legit.trigger then
                        engine.execute_client_cmd('+use');
                    end;
                    antiaim.legit.trigger = false;
                    return;
                end;

                if state ~= 'On use' then
                    antiaim.legit.trigger = false;
                    return;
                end;

                if antiaim.legit.trigger then
                    return;
                end;

                engine.execute_client_cmd('-use');
                antiaim.legit.trigger = true;
            end;
        end;

        local native_enabled = source.enabled:get();

        ---@param cmd user_cmd_t
        local function setup(cmd)
            source.enabled:set(enable:get());

            local state = antiaim:get_statement(cmd);
            state = information[state].override:get() and state or 'Default';

            local settings = information[state];

            for name, element in pairs(nixware_elements) do
                element:set(settings[name]:get());
            end;

            antiaim.legit.handle(state);
            antiaim.fakelag.handle(settings, cmd);
            antiaim.defensive.handle(settings, cmd);
        end;

        register_callback('create_move', function(cmd)
            xpcall(setup, print, cmd);
        end);

        register_callback('unload', function()
            source.enabled:set(native_enabled);
        end);
    end;
end;

local visualization = {}; do
    ---@private
    local handle = ui.create('Visualization');

    local widgets = {}; do
        local master = handle:multicombo('Select widgets:', { 'Watermark', 'Keybinds', 'Spectators' });
        local accent_color = handle:color('Accent color', color_t.new(0.647, 0.813, 1, 1), false);

        local function watermark()
            local local_player = entitylist.get_local_player();

            local alpha_anim = animation:new('watermark_alpha', nil, master:get(0));
            local margin = 8;

            local accent_color = accent_color:get();
            accent_color.a = alpha_anim;

            local position = vec2_t.new(screen.x - 500, margin);

            local latency = 0;
            if local_player and local_player:is_alive() then
                local net_channel = engine_client:get_net_channel_info();
                latency = (net_channel:get_latency(0)) * 1000;
            end;

            local user_name = get_user_name();
            local current_time = os.date('%I:%M %p');
            local formatted_latency = string.format('%.1f ms', latency);
            local watermark_text = string.format(' %s \a414141ff|\adefault %s \a414141ff|\adefault %s ', user_name, formatted_latency, current_time);

            local icon = 'NIGHTMARE';
            local text_size = render.measure_text(font.text[18], watermark_text);
            local icon_size = render.measure_text(font.icons[16], icon);

            local padding = 10;
            local height = text_size.y + icon_size.y + (padding * 2) + (margin * 2);
            local width = text_size.x + (margin * 2);

            position.x = screen.x - width - margin;

            local background_color = color_t.new(0.12, 0.12, 0.12, alpha_anim);
            local divider_color = color_t.new(0.25, 0.25, 0.25, alpha_anim);
            local border_radius = 6;

            render.rect_filled(position, position + vec2_t.new(width, height), background_color, border_radius);
            render.rect(position + 1, position + vec2_t.new(width, height) - 1, divider_color, border_radius, 2);

            render.text(font.icons[16], position + vec2_t.new(width * 0.5, margin), accent_color, 'c', icon);

            local divider_start = position + vec2_t.new(margin, icon_size.y + margin + padding);
            local divider_end = position + vec2_t.new(width - margin, icon_size.y + margin + padding + 2);
            render.rect_filled(divider_start, divider_end, divider_color);

            render.text(font.text[18], position + vec2_t.new(margin, height - text_size.y - margin), color_t.new(0.9, 0.9, 0.9, alpha_anim), '', watermark_text);
        end;

        register_callback('paint', function()
            xpcall(watermark, print);
        end);
    end;

    local third_person = {}; do
        local old_value = cvars.cam_idealdist:get_int();
        local camera_distance = handle:slider_int('3rd person distance', 30, 180, old_value);

        register_callback('paint', function()
            local distance = camera_distance:get();
            local delta = math.abs(old_value - distance);

            if delta > 0.1 then
                old_value = math.lerp(old_value, distance, 0.2);
                cvars.cam_idealdist:set_float(old_value);
            end;
        end);
    end;

    local viewmodel_in_scope = {}; do
        local enable = handle:switch('Viewmodel in scope');
        ---@cast enable -c_tab

        convar_manager.new('Viewmodel in scope', {
            { 'fov_cs_debug', 90, 0 },
        }, enable);
    end;

    local grenade_esp = {}; do
        local group, enable = handle:switch('Grenade ESP', false, true);

        -- local molotov = group:color('Molotov', color_t.new(255 / 255, 177 / 255, 177 / 255, 1), true, true);
        local smoke = group:switch('Smoke');
        local smoke_color = group:color('Smoke color', color_t.new(1, 1, 1, 1), false);

        local frag = group:switch('Frag');
        local frag_color = group:color('Frag color', color_t.new(1, 1, 1, 1), false);

        local FONT = render.fonts.DEFAULT;

        function grenade_esp.on_paint()
            entitylist.get_entities('CSmokeGrenadeProjectile', false, function(entity)
                local m_nSmokeEffectTickBegin = ffi.cast('int*', entity[netvars.m_nSmokeEffectTickBegin])[0];
                local m_bDidSmokeEffect = ffi.cast('bool*', entity[netvars.m_bDidSmokeEffect])[0];

                local active = enable:get() and smoke:get();

                local bar_animation = animation:new(string.format('smoke %s bar', entity[0]), 0, active and m_nSmokeEffectTickBegin ~= 0);
                local alpha_animation = animation:new(string.format('smoke %s alpha', entity[0]), 0, active and (m_nSmokeEffectTickBegin == 0 or globals.tick_count - (m_nSmokeEffectTickBegin) <= 1140));
                local radius_animation = animation:new(string.format('smoke %s radius', entity[0]), 0, active and m_bDidSmokeEffect);

                do -- radius
                    local out_color = smoke_color:get();
                    local in_color = smoke_color:get();
                    out_color.a = out_color.a * alpha_animation;
                    in_color.a = in_color.a * .5 * alpha_animation;

                    render.circle_filled_3d(entity:get_origin(), 145 * radius_animation, in_color);
                    render.circle_3d(entity:get_origin(), 145 * radius_animation, out_color);
                end;

                do -- info
                    local color = smoke_color:get();
                    color.a = 1 * alpha_animation;

                    local origin = entity:get_origin();

                    local text = 'smoke';
                    local text_size = render.measure_text(FONT, text);

                    local pct = 1 - (globals.tick_count - (m_nSmokeEffectTickBegin)) / 1155;
                    local w2s = render.world_to_screen(origin);

                    if w2s then
                        w2s = w2s - text_size * .5;

                        w2s.x = math.floor(w2s.x + .5);
                        w2s.y = math.floor(w2s.y + .5);

                        render.text(FONT, w2s, color, 's', text);

                        w2s.y = w2s.y + text_size.y + 2;
                        text_size.y = 4;

                        render.rect_filled(w2s, w2s + text_size, color_t.new(0, 0, 0, .5 * bar_animation * alpha_animation));

                        text_size.x = (text_size.x - 2) * pct;
                        text_size.y = text_size.y - 1;

                        local color = smoke_color:get();
                        color.a = 1 * bar_animation * alpha_animation;

                        render.rect_filled(w2s + 1, w2s + text_size + vec2_t.new(1, 0), color);
                    end;
                end;
            end);

            entitylist.get_entities('CBaseCSGrenade', false, function(entity)
                local m_nExplodeEffectTickBegin = ffi.cast('int*', entity[netvars.m_nExplodeEffectTickBegin])[0];
                local m_flSimulationTime = ffi.cast('float*', entity[netvars.m_flSimulationTime])[0];
                local m_nGrenadeSpawnTime = ffi.cast('float*', entity[netvars.m_nGrenadeSpawnTime])[0];

                local active = enable:get() and frag:get();

                local alpha_animation = animation:new(string.format('frag %s alpha', entity[0]), 0, active and m_nExplodeEffectTickBegin == 0);

                do -- info
                    local origin = entity:get_origin();

                    local text = 'frag';
                    local text_size = render.measure_text(FONT, text); -- защита от гномика

                    local pct = 1 - (m_flSimulationTime - m_nGrenadeSpawnTime) / 1.640625;
                    local w2s = render.world_to_screen(origin);

                    if w2s then
                        local color = frag_color:get();
                        color.a = 1 * alpha_animation;

                        w2s = w2s - text_size * .5;

                        w2s.x = math.floor(w2s.x + .5);
                        w2s.y = math.floor(w2s.y + .5);

                        render.text(FONT, w2s, color, 's', text);

                        w2s.y = w2s.y + text_size.y + 2;
                        text_size.y = 4;

                        render.rect_filled(w2s, w2s + text_size, color_t.new(0, 0, 0, .5 * alpha_animation));

                        text_size.x = (text_size.x - 2) * pct;
                        text_size.y = text_size.y - 1;

                        render.rect_filled(w2s + 1, w2s + text_size + vec2_t.new(1, 0), color);
                    end;
                end;
            end);
        end;

        register_callback('paint', function()
            xpcall(grenade_esp.on_paint, print);
        end);
    end;

    local predict = {}; do
        local enable = handle:switch('Show extrapolated position');

        local function main()
            if not enable:get() then
                return;
            end;

            local me = entitylist.get_local_player();
            if not (me and me:is_alive()) then
                return;
            end;

            local position = extrapolation.get(me);
            if not position then
                return;
            end;

            render.circle_3d(position, 15, color_t.new(1, 1, 1, 1));
        end;

        register_callback('paint', function()
            xpcall(main, print);
        end);
    end;
end;

local misc = {}; do
    ---@private
    local handle = ui.create('Misc');

    local killsay = {}; do
        local class, switch = handle:switch('Killsay', false, true);
        local CPM = class:slider_int('Characters per minute', 200, 1000, 800); -- Characters per minute

        ---@type table<number, {list: string[], flags?: table<boolean?>}>
        local phrases = require 'libs.phrases';
        local already_writing = false;

        local function time_for_phrase(phrase, cpm)
            local totalTime = 0;
            local cpm = (cpm / 300);

            for i = 1, #phrase do
                local char = phrase:sub(i, i):lower();
                local speed = TypingSpeeds[char] or 300;
                speed = speed;
                totalTime = totalTime + (60 / (speed * cpm));
            end;

            return totalTime;
        end;

        local function is_event_valid(event)
            local userid = event:get_int('userid');
            local attacker_id = event:get_int('attacker');

            local died = entitylist.get(userid, true);
            local attacker = entitylist.get(attacker_id, true);
            local me = entitylist.get_local_player();

            if not (me and died and attacker) then
                return;
            end;

            local my_index = me:get_index();
            local attacker_index = attacker:get_index();

            if died:get_index() == my_index then
                if attacker_index == my_index then
                    return 'on_suicide';
                else
                    return 'on_death';
                end;
            end;

            if attacker_index ~= my_index then
                return;
            end;

            return 'on_kill';
        end;

        ---@param event game_event_t
        ---@param flags table
        local function is_valid_flags(event, flags)
            if type(flags) ~= 'table' then
                return true;
            end;

            for name, value in pairs(flags) do
                local value_type = type(value);

                if value_type == 'number' then
                    if event:get_int(name) == 0 then
                        return;
                    end;
                elseif value_type == 'string' then
                    if not event:get_string(name):find(value) then
                        return;
                    end;
                elseif value_type == 'boolean' then
                    if event:get_bool(name) ~= value then
                        return;
                    end;
                end;
            end;

            return true;
        end;

        local function filter_phrases(phrases, event)
            local filtered_phrases = {};

            for _, phrase in ipairs(phrases) do
                if is_valid_flags(event, phrase.flags) then
                    table.insert(filtered_phrases, phrase);
                end;
            end;

            return filtered_phrases;
        end;

        local function send_phrase(phrase, id)
            local last_duration = 0;

            for i, phrase in pairs(phrase.list) do
                local duration = time_for_phrase(phrase, CPM:get());
                timers.new(
                    string.format('killsay_%s_%s', id, i),
                    0.5 + duration + last_duration,
                    function()
                        engine.execute_client_cmd(string.format('say "%s"', phrase));
                    end,
                    true
                );

                last_duration = last_duration + duration;
            end;

            timers.new(
                string.format('killsay_%s_end', id),
                0.5 + last_duration,
                function()
                    already_writing = false;
                end,
                true
            );
        end;

        ---@param event game_event_t
        local function main(event)
            if not switch:get() then
                return;
            end;

            if already_writing then
                return;
            end;

            local event_type = is_event_valid(event);

            if not event_type then
                return;
            end;

            already_writing = true;

            local filtered_phrases = filter_phrases(phrases[event_type], event);
            local id = math.random(1, #filtered_phrases);
            local phrase = filtered_phrases[id];

            send_phrase(phrase, id);
        end;

        register_callback('player_death', main);
    end;

    local console_filter; do
        local enable = handle:switch('Enable console filter', true);
        ---@cast enable -c_tab

        convar_manager.new('Console filter', {
            { 'con_filter_enable', true,        false },
            { 'con_filter_text',   'nightmare', '' }
        }, enable);
    end;

    local disable_panorama_blur; do
        local enable = handle:switch('Disable panorama blur', true);
        ---@cast enable -c_tab

        convar_manager.new('Disable panorama blur', {
            { '@panorama_disable_blur', 1, 0 },
        }, enable);
    end;

    local fast_stop = {}; do
        local enable = handle:switch('Fast stop', true);

        local function main(cmd)
            if not enable:get() then
                return;
            end;

            local me = entitylist.get_local_player();

            if not (me and me:is_alive()) then
                return;
            end;

            local in_move = bit.band(cmd.buttons, IN.BACK + IN.FORWARD + IN.MOVELEFT + IN.MOVERIGHT) ~= 0;
            if in_move then
                return;
            end;

            local flags = me:get_flags();
            if bit.hasnt(flags, FL.ONGROUND) or bit.has(cmd.buttons, IN.JUMP) then
                return;
            end;

            local velocity = me:get_velocity();
            local speed = velocity:length2d();

            if speed <= 15 then
                return;
            end;

            local direction = velocity:to_angle();
            direction.yaw = normalize_yaw(cmd.viewangles.yaw - direction.yaw);

            local negated_direction = direction:forward() * -speed;

            cmd.forwardmove = negated_direction.x;
            cmd.sidemove = negated_direction.y;
        end;

        register_callback('create_move', main);
    end;
end;

local skinchanger = {}; do
    -- Снизу все обосрано и обдристано. НЕ ПРИБЛИЖАТЬСЯ ЕСЛИ ВЫ НЕ УВЕРЕНЫ ЧТО ДЕЛАЕТЕ!!! ИНАЧЕ ВЫ МОЖЕТЕ СРАСТИСЬ С ДЕРЬМОМ!!!
    -- upd #1: Теперь менее обосрано
    local handle = ui.create('Skinchanger');
    local weapon_data = require 'libs.weapon_skins';

    local weapon_names = {
        'weapon_ak47', 'weapon_aug', 'weapon_awp', 'weapon_bizon', 'weapon_cz75a', 'weapon_deagle',
        'weapon_elite', 'weapon_famas', 'weapon_fiveseven', 'weapon_g3sg1', 'weapon_galilar', 'weapon_glock',
        'weapon_m249', 'weapon_m4a1', 'weapon_m4a1_silencer', 'weapon_mac10', 'weapon_mag7', 'weapon_mp5sd',
        'weapon_mp7', 'weapon_mp9', 'weapon_negev', 'weapon_nova', 'weapon_hkp2000', 'weapon_p250', 'weapon_p90',
        'weapon_revolver', 'weapon_sawedoff', 'weapon_scar20', 'weapon_ssg08', 'weapon_sg556', 'weapon_tec9',
        'weapon_ump45', 'weapon_usp_silencer', 'weapon_xm1014',
        'weapon_knife'
    };

    local formatted_weapon_names = {
        'AK-47', 'AUG', 'AWP', 'PP-Bizon', 'CZ75-Auto', 'Desert Eagle', 'Dual Berettas', 'FAMAS', 'Five-SeveN',
        'G3SG1', 'Galil AR', 'Glock-18', 'M249', 'M4A4', 'M4A1-S', 'MAC-10', 'MAG-7', 'MP5-SD', 'MP7', 'MP9',
        'Negev', 'Nova', 'P2000', 'P250', 'P90', 'R8 Revolver', 'Sawed-Off', 'SCAR-20', 'SSG 08', 'SG 553',
        'Tec-9', 'UMP-45', 'USP-S', 'XM1014',
        'Knife',
    };

    local knife_names = {
        'weapon_knife', 'weapon_knife_t', 'weapon_bayonet', 'weapon_knife_flip', 'weapon_knife_gut',
        'weapon_knife_karambit', 'weapon_knife_m9_bayonet', 'weapon_knife_tactical', 'weapon_knife_falchion',
        'weapon_knife_survival_bowie', 'weapon_knife_butterfly', 'weapon_knife_push'
    };

    local formatted_knife_name = {
        'Knife', 'Knife (Terrorist)', 'Bayonet', 'Flip Knife', 'Gut Knife',
        'Karambit', 'M9 Bayonet', 'Huntsman Knife', 'Falchion Knife',
        'Bowie Knife', 'Butterfly Knife', 'Shadow Daggers'
    };

    local weapon2index = {};
    for i, v in ipairs(weapon_names) do
        weapon2index[v] = i - 1;
    end;

    local native_GetWeaponInfo = ffi.cast('weapon_info_t*(__thiscall*)(uintptr_t)', find_pattern('client.dll', '55 8B EC 81 EC 0C 01 ? ? 53 8B D9 56 57 8D 8B'));
    local native_GetModelIndex = memory:get_vfunc('engine.dll', 'VModelInfoClient004', 2, 'int(__thiscall*)(void*, const char*)');
    local native_SetModelIndex = memory:get_vfunc(75, 'void(__thiscall*)(void*, int)');
    local m_nDeltaTick = ffi.cast('int*', ffi.cast('uintptr_t', ffi.cast('uintptr_t***', (ffi.cast('uintptr_t**', memory:create_interface('engine.dll', 'VEngineClient014'))[0][12] + 16))[0][0]) + 0x0174);

    local IBaseClientDLL = vmt:new(memory:create_interface('client.dll', 'VClient018'));

    local WEAPON_KNIFE_DEF_IDX = KNIFE_IDXs.WEAPON_KNIFE_M9_BAYONET;
    local WEAPON_KNIFE_MDL_PATH = KNIFE_MDLs[WEAPON_KNIFE_DEF_IDX];

    local WEAPON_KNIFE_MDL_IDX = native_GetModelIndex(WEAPON_KNIFE_MDL_PATH);

    local paint_kits = {};
    local default_paint_kits = {};

    local gui = {
        weapons         = {},
        knife_selector  = handle:combo('Knife selector', formatted_knife_name),
        weapon_selector = handle:combo('Weapon selector', formatted_weapon_names),
    };

    local last_knife = gui.knife_selector:get();

    for i, name in ipairs(weapon_names) do
        local weapon_config = {
            skin = handle:combo('Skin selector##' .. name, weapon_data[name].skin_names, math.random(0, #weapon_data[name].skin_names - 1)),
            wear = handle:slider_float('Wear ##' .. name, 0.001, 1.0, 0.001),
            seed = handle:slider_int('Seed ##' .. name, 1, 1000, 1),
            custom_color = handle:switch('Custom color ##' .. name),

            handle:color('Color 1##' .. name, nil, true, false),
            handle:color('Color 2##' .. name, nil, true, false),
            handle:color('Color 3##' .. name, nil, true, false),
            handle:color('Color 4##' .. name, nil, true, false)
        };

        for id, element in pairs(weapon_config) do
            element:depend({
                { gui.weapon_selector, i - 1 },
                type(id) == 'number' and { weapon_config.custom_color, true } or nil,
            });
        end;

        gui.weapons[name] = weapon_config;
    end;

    local schema, paint_kit_color; do
        local function read(typename, address)
            if address == nil then
                return function(address)
                    return ffi.cast(ffi.typeof(typename .. '*'), ffi.cast('uint32_t ', address))[0];
                end;
            end;
            return ffi.cast(ffi.typeof(typename .. '*'), ffi.cast('uint32_t ', address))[0];
        end;

        local function follow_call(ptr)
            local insn = ffi.cast('uint8_t*', ptr);

            if insn[0] == 0xE8 then
                local offset = ffi.cast('int32_t*', insn + 1)[0];

                return insn + offset + 5;
            elseif insn[0] == 0xFF and insn[1] == 0x15 then
                local call_addr = ffi.cast('uint32_t**', ffi.cast('const char*', ptr) + 2);

                return call_addr[0][0];
            elseif insn[0] == 0xB0 then
                return ffi.cast('uint32_t', ptr + 4 + read('uint32_t', ptr));
            else
                error(string.format('unknown instruction to follow: %02X!', insn[0]));
            end;
        end;

        local string_t = [[struct { char* buffer; int capacity; int grow_size; int length; }]];
        local paint_kit_t = string.format([[
            struct {
                int nID;
                %s name;
                %s description;
                %s tag;
                %s same_name_family_aggregate;
                %s pattern;
                %s normal;
                %s logoMaterial;
                bool baseDiffuseOverride;
                int rarity;
                int style;
                uint8_t color[4][4];
                char pad[35];
                float wearRemapMin;
                float wearRemapMax;
            }
        ]], string_t, string_t, string_t, string_t, string_t, string_t, string_t);

        local create_map_t = function(key_type, value_type)
            return ffi.typeof([[struct {
                void* lessFunc;
                struct {
                    struct {
                        int left;
                        int right;
                        int parent;
                        int type;
                        $ key;
                        $ value;
                    }* memory;
                    int allocationCount;
                    int growSize;
                } memory;
                int root;
                int num_elements;
                int firstFree;
                int lastAlloc;
                struct {
                    int left;
                    int right;
                    int parent;
                    int type;
                    $ key;
                    $ value;
                }* elements;
            }]], ffi.typeof(key_type), ffi.typeof(value_type), ffi.typeof(key_type), ffi.typeof(value_type));
        end;

        local item_schema_t = ffi.typeof([[struct { $ paint_kits; }*]], create_map_t('int', paint_kit_t .. '*'));
        local get_item_schema_addr = find_pattern('client.dll', ' A1 ? ? ? ? 85 C0 75 53') or error('cant find get_item_scham()');
        local get_item_schema_fn = ffi.cast('uint32_t(__stdcall*)()', get_item_schema_addr);

        local get_paint_kit_definition_addr = find_pattern('client.dll', ' E8 ? ? ? ? 8B F0 8B 4E 7C') or error('cant find get_paint_kit_definition');
        local get_paint_kit_definition_fn = ffi.cast('void*(__thiscall*)(void*, int)', follow_call(get_paint_kit_definition_addr));

        function paint_kit_color(obj, c)
            obj[0] = c.r * 255;
            obj[1] = c.g * 255;
            obj[2] = c.b * 255;
            obj[3] = c.a * 255;
        end;

        local item_schema_c = {}; do
            function item_schema_c.create(ptr)
                return setmetatable({
                    ptr = ptr,
                }, {
                    __index = item_schema_c,
                    __metatable = 'item_schema'
                });
            end;

            function item_schema_c:get_paint_kit(index)
                local paint_kit_addr = get_paint_kit_definition_fn(self.ptr, index);
                if paint_kit_addr == nil then return; end;

                ---@diagnostic disable-next-line: param-type-mismatch
                return ffi.cast(ffi.typeof(paint_kit_t .. '*'), paint_kit_addr);
            end;
        end;

        schema = item_schema_c.create(ffi.cast(item_schema_t, get_item_schema_fn() + 4));
    end;

    local function set_model(weapon, model_index, item_index)
        ffi.cast('int*', weapon + netvars.m_iEntityQuality)[0] = 3;
        ffi.cast('int*', weapon + netvars.m_iItemDefinitionIndex)[0] = item_index;
        ffi.cast('int*', weapon + netvars.m_nModelIndex)[0] = model_index;
        native_SetModelIndex(ffi.cast('void*', weapon), model_index);
    end;

    local function apply_skin(weapon, weapon_info)
        local weapon_name = ffi.string(weapon_info.ConsoleName);
        local gui_weapon = gui.weapons[weapon_name];
        if not gui_weapon then
            return;
        end;

        local selected_skin = gui_weapon.skin:get();
        local wear = gui_weapon.wear:get();
        local seed = gui_weapon.seed:get();
        local custom_color = gui_weapon.custom_color:get();

        local skin_name = weapon_data[weapon_name].skin_names[selected_skin + 1];
        local skin_id = weapon_data[weapon_name].skin_ids[skin_name];
        if not skin_id then
            return;
        end;

        local paint_kit = paint_kits[skin_id] or schema:get_paint_kit(skin_id);
        paint_kits[skin_id] = paint_kit;

        local cache = default_paint_kits[weapon_name] or {};
        default_paint_kits[weapon_name] = cache;
        cache[skin_id] = cache[skin_id] or {};

        for x = 1, 4 do
            local ref = gui.weapons[weapon_name][x];

            ---@diagnostic disable-next-line: need-check-nil, undefined-field
            local kit_color = paint_kit.color[x - 1];

            if (default_paint_kits[weapon_name][skin_id][x] == nil) then
                default_paint_kits[weapon_name][skin_id][x] = color_t.new(kit_color[0] / 255, kit_color[1] / 255, kit_color[2] / 255, kit_color[3] / 255);

                ref:set(default_paint_kits[weapon_name][skin_id][x]);
            end;

            local color = custom_color and ref:get() or default_paint_kits[weapon_name][skin_id][x];

            ref:set(color);

            paint_kit_color(kit_color, color);
        end;

        local item_id_high = ffi.cast('int*', weapon + netvars.m_iItemIDHigh);
        local fallback_paint_kit = ffi.cast('int*', weapon + netvars.m_nFallbackPaintKit);
        local fallback_wear = ffi.cast('float*', weapon + netvars.m_flFallbackWear);
        local fallback_seed = ffi.cast('int*', weapon + netvars.m_nFallbackSeed);

        if item_id_high[0] ~= -1 or fallback_paint_kit[0] ~= skin_id or fallback_wear[0] ~= wear or fallback_seed[0] ~= seed then
            item_id_high[0] = -1;
            fallback_paint_kit[0] = skin_id;
            fallback_wear[0] = wear;
            fallback_seed[0] = seed;

            m_nDeltaTick[0] = -1;
        end;
    end;

    local function apply_knife_skin(me, weapon)
        local weapon_handle = ffi.cast('int*', me[netvars.m_hActiveWeapon]);
        if not weapon_handle then
            return;
        end;

        local active_weapon = IClientEntityList:GetClientEntityFromHandle(weapon_handle[0]);
        if not active_weapon then
            return;
        end;

        set_model(weapon, WEAPON_KNIFE_MDL_IDX, WEAPON_KNIFE_DEF_IDX);

        local view_model_handle = ffi.cast('int*', me[netvars.m_hViewModel])[0];
        if view_model_handle == -1 then
            return;
        end;

        local view_model = IClientEntityList:GetClientEntityFromHandle(view_model_handle);
        if active_weapon == weapon then
            ffi.cast('int*', view_model + netvars.m_nModelIndex)[0] = WEAPON_KNIFE_MDL_IDX;
        end;
    end;

    local function skin_changer(me)
        local my_weapons = ffi.cast('int*', me[netvars.m_hMyWeapons]);
        for i = 0, 10 do
            local weapon_handle = my_weapons[i];
            if weapon_handle ~= -1 then
                local weapon = entitylist.from_handle(weapon_handle);
                if weapon then
                    local weapon_info = native_GetWeaponInfo(weapon);
                    if weapon_info then
                        local weapon_name = ffi.string(weapon_info.ConsoleName);
                        if weapon_name:find('knife') then
                            apply_knife_skin(me, weapon);
                        elseif gui.weapons[weapon_name] then
                            apply_skin(weapon, weapon_info);
                        end;
                    end;
                end;
            end;
        end;
    end;

    local function menu_handler(me)
        local weapon_handle = ffi.cast('int*', me[netvars.m_hActiveWeapon]);
        if not weapon_handle then return; end;

        local weapon = IClientEntityList:GetClientEntityFromHandle(weapon_handle[0]);
        if not weapon then
            return;
        end;

        local knife_type = gui.knife_selector:get();
        if last_knife ~= knife_type then
            IDX = KNIFE_IDXs[knife_names[knife_type + 1]:upper()];
            if IDX then
                local MDL_PATH = KNIFE_MDLs[IDX];
                WEAPON_KNIFE_DEF_IDX = IDX;
                WEAPON_KNIFE_MDL_IDX = native_GetModelIndex(MDL_PATH);
            end;
            last_knife = knife_type;
        end;

        local weapon_info = native_GetWeaponInfo(weapon);
        if not weapon_info then
            return;
        end;

        local weapon_name = ffi.string(weapon_info.ConsoleName);
        local is_knife = weapon_name:find('knife');
        if not gui.weapons[weapon_name] and not is_knife then
            return;
        end;

        if not menu.is_visible() or not gui.weapon_selector:is_visible() then
            if is_knife then
                gui.weapon_selector:set(weapon2index['weapon_knife']);
            else
                gui.weapon_selector:set(weapon2index[weapon_name]);
            end;
        end;
    end;

    IBaseClientDLL:attach(37, 'void(__stdcall*)(int stage)', function(stage)
        IBaseClientDLL:get_original(37)(stage);

        xpcall(function()
            if stage == FrameStages.FRAME_NET_UPDATE_POSTDATAUPDATE_START then
                local me = entitylist.get(engine_client:get_local_player());
                if me and me:is_alive() then
                    skin_changer(me);
                    menu_handler(me);
                end;
            end;
            if stage == FrameStages.FRAME_NET_UPDATE_START then
                exploit:on_net_update_start();
            end;
        end, print);
    end);

    register_callback('unload', function()
        xpcall(function()
            for _, paint_kit_list in pairs(default_paint_kits) do
                for skin_id, colors in pairs(paint_kit_list) do
                    local paint_kit = paint_kits[skin_id];

                    for x, color in ipairs(colors) do
                        local kit_color = paint_kit.color[x - 1];
                        paint_kit_color(kit_color, color);
                    end;
                end;
            end;

            m_nDeltaTick[0] = -1;
        end, print);
    end);
end;


--#endregion

--#region: Post load
engine.execute_client_cmd('clear');
utils:play_sound('ui/item_drop.wav');
printf('welcome back, %s!', get_user_name());
printf('lua fully initialized in %.3f seconds', os.clock() - LOAD_TIME);

register_callback('unload', function()
    print('bye! ;(');
end);
--#endregion
