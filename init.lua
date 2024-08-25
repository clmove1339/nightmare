do
    local get_csgo_folder = function()
        local source = debug.getinfo(1, 'S').source:sub(2, -1);
        return source:match('^(.-)nix/') or source:match('^(.-)lua\\');
    end;

    local csgo_folder = get_csgo_folder();
    package.path = package.path .. string.format('%slua\\nightmare\\?.lua;', csgo_folder);
    package.path = package.path .. string.format('%slua\\nightmare\\?\\init.lua;', csgo_folder);
end;

require 'libs.enums';
require 'libs.global';
require 'libs.entity';

local timers = require 'libs.timers';
local memory = require 'libs.memory';
local ui = require 'libs.ui';
local utils = require 'libs.utils';
local engine_client = require 'libs.engine_client';
local vmt = require 'libs.vmt';
local inspect = require 'libs.inspect';

local aimbot = {}; do
    ---@private
    local handle = ui.create('Aimbot');

    local custom_resolver = handle:switch('ENABLE CUSTOM_RESOZOLVER', nil, true);
    local resolver_type = custom_resolver:combo('Resolver Type', { 'Off', 'Default', 'Extended' });
end;

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-aimbot');
    local enable = handle:switch('Enabled');
    local sub_handle = handle:combo('Anti-aimbot part:', { 'General', 'Settings' });

    sub_handle:depend({ { enable, true } });

    antiaim.general = {}; do
        local features = handle:multicombo('Features', { 'Anti-backstab', 'Manual anti-aim' });

        local manual = {
            left = handle:keybind('Manual left'),
            right = handle:keybind('Manual right'),
            reset = handle:keybind('Manual reset'),
            static = handle:switch('Use static on manual'),
        };

        features:depend({ { enable, true }, { sub_handle, 0 } });
        manual.left:depend({ { enable, true }, { sub_handle, 0 }, { features, 1 } });
        manual.right:depend({ { enable, true }, { sub_handle, 0 }, { features, 1 } });
        manual.reset:depend({ { enable, true }, { sub_handle, 0 }, { features, 1 } });
        manual.static:depend({ { enable, true }, { sub_handle, 0 }, { features, 1 } });
    end;

    local states = { 'Default', 'Standing', 'Running', 'Walking', 'Crouching', 'Sneaking', 'In Air', 'In Air & Crouching', 'On use' };

    ---@param cmd user_cmd_t
    ---@return 'Default'|'Standing'|'Running'|'Walking'| 'Crouching'|'Sneaking'|'In Air'|'In Air & Crouching'|'On use'
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
        local in_use = bit.has(cmd.buttons, IN.USE);

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
        ---@type table<string, menu_item[]>
        local information = {};
        local state_selector = handle:combo('State', states, 0);

        state_selector:depend({ { enable, true }, { sub_handle, 1 } });

        local function setup_state(state, index)
            local info = {
                override = handle:switch('Override ' .. state, state == 'Default'),
                pitch = handle:combo('Pitch##' .. state, { 'None', 'Down', 'Fake down', 'Fake up' }, 1),
                base_yaw = handle:combo('Base yaw##' .. state, { 'Local view', 'Static', 'At targets' }, 2),
                yaw_offset = handle:slider_int('Yaw offset##' .. state, -180, 180, 180),
                yaw_modifier = handle:combo('Yaw modifier##' .. state, { 'None', 'Center', 'Offset', 'Random', '3-Way', '5-Way' }, 0),
                yaw_modifier_offset = handle:slider_int('Yaw modifier offset##' .. state, -180, 180, 0),
                yaw_desync = handle:combo('Yaw desync##' .. state, { 'None', 'Static', 'Jitter', 'Random Jitter' }),
                yaw_desync_length = handle:slider_int('Yaw desync length##' .. state, 0, 60, 0),
                enable_fakelag = handle:switch('Enable fakelag##' .. state, false, false, 'Movement/Fakelag'),
                fakelag_type = handle:combo('Fakelag type##' .. state, { 'Off', 'Static', 'Fluctuation', 'Adaptive', 'Random' }, nil, 'Movement/Fakelag'),
                fakelag_limit = handle:slider_int('Fakelag limit##' .. state, 0, 16, 0, 'Movement/Fakelag'),
            };

            for element_name, element in pairs(info) do
                local is_default_state = state == 'Default';
                local is_override_checkbox = element_name == 'override';

                element:depend({
                    { enable,         true },
                    { state_selector, index - 1 },
                    { sub_handle,     1 },
                    not (is_default_state and is_override_checkbox),
                    (is_default_state or is_override_checkbox) and true or { info.override, true },
                });
            end;

            --[[ На будущее
            state_selector:connect({
                [index] = {
                    info.override,
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
                    }
                }
            }); ]]

            information[state] = info;
        end;

        for i, state in ipairs(states) do
            setup_state(state, i);
        end;

        local base_path = 'Movement/Anti aim';

        local nixware_elements = {
            pitch = menu.find_combo_box('Pitch', base_path),
            base_yaw = menu.find_combo_box('Base yaw', base_path),
            yaw_offset = menu.find_slider_int('Yaw offset', base_path),
            yaw_modifier = menu.find_combo_box('Yaw modifier', base_path),
            yaw_modifier_offset = menu.find_slider_int('Yaw modifier offset', base_path),
            yaw_desync = menu.find_combo_box('Yaw desync', base_path),
            yaw_desync_length = menu.find_slider_int('Yaw desync length', base_path),
        };

        antiaim.fakelag = {}; do
            local cache = {};
            local server_origin = vec3_t.new(0, 0, 0);

            ---@param state table
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
                    local velocity = me:get_velocity();
                    local speed = math.sqrt(velocity.x ^ 2 + velocity.y ^ 2 + velocity.z ^ 2);
                    local speed_per_tick = speed * globals.interval_per_tick;
                    local lag_for_lc = math.floor(64 / speed_per_tick) + 2;

                    if lag_for_lc > 16 then
                        cmd.send_packet = choked >= limit;
                    else
                        cmd.send_packet = choked >= lag_for_lc;
                    end;
                elseif type == 4 then
                    if not cache[2] then
                        cache[2] = math.random(limit, 15);
                    end;

                    local bSendPacket = choked >= cache[2];

                    cmd.send_packet = bSendPacket;

                    if bSendPacket then
                        cache[2] = math.random(limit, 15);
                    end;
                end;

                if cmd.send_packet then
                    local origin = me:get_origin();
                    local dx, dy, dz = origin.x - server_origin.x, origin.y - server_origin.y, origin.z - server_origin.z;
                    local distance = math.sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2);

                    if _DEV then
                        printf('lc: %s', distance > 64);
                        printf('distance: %.2f', distance);
                        printf('choked: %d\n', globals.choked_commands);
                    end;

                    server_origin = vec3_t.new(origin.x, origin.y, origin.z);
                end;
            end;
        end;

        local native_enabled = nixware['Movement']['Anti aim'].enabled:get();

        ---@param cmd user_cmd_t
        local function setup(cmd)
            nixware['Movement']['Anti aim'].enabled:set(enable:get());

            local state = antiaim:get_statement(cmd);
            ---@diagnostic disable-next-line: undefined-field
            state = information[state].override:get() and state or 'Default';

            local settings = information[state];

            for name, element in pairs(nixware_elements) do
                element:set(settings[name]:get());
            end;

            antiaim.fakelag.handle(settings, cmd);
        end;

        register_callback('create_move', function(cmd)
            xpcall(setup, print, cmd);
        end);

        register_callback('unload', function()
            nixware['Movement']['Anti aim'].enabled:set(native_enabled);
        end);
    end;
end;

local visualization = {}; do
    ---@private
    local handle = ui.create('Visualization');

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
        local old_value = cvars.fov_cs_debug:get_int() == 90; -- fov_cs_debug
        local enable = handle:switch('Viewmodel in scope');

        register_callback('paint', function()
            local enable = enable:get();

            if old_value ~= enable then
                cvars.fov_cs_debug:set_int(enable and 90 or 0);
                old_value = enable;
            end;
        end);
    end;
end;

local misc = {}; do
    ---@private
    local handle = ui.create('Misc');

    local killsay = {}; do
        local class, switch = handle:switch('Killsay', false, true);
        local CPM = class:slider_int('Characters per minute', 200, 500, 300); -- Characters per minute

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

            if died:get_index() == my_index then
                return;
            end;

            if attacker:get_index() ~= my_index then
                return;
            end;

            return true;
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

        local function filter_phrases(event)
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
                0.1 + last_duration,
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

            if not is_event_valid(event) then
                return;
            end;

            already_writing = true;

            local valid_phrases = filter_phrases(event);
            local id = math.random(1, #valid_phrases);
            local phrase = valid_phrases[id];

            send_phrase(phrase, id);
        end;

        register_callback('player_death', main);
    end;

    local console_filter; do
        local old_value = cvars.con_filter_enable:get_bool();
        local enable = handle:switch('Enable console filter');

        register_callback('paint', function()
            local enable = enable:get();
            if old_value ~= enable then
                cvars.con_filter_enable:set_bool(enable);
                cvars.con_filter_text:set_string('nightmare');
                old_value = enable;
            end;
        end);
    end;
end;

local skinchanger = {}; do
    --#region: Ponos deda
    local IClientEntityList = memory:interface('client', 'VClientEntityList003', {
        GetClientEntity = { 3, 'uintptr_t(__thiscall*)(void*, int)' },
        GetClientEntityFromHandle = { 4, 'uintptr_t(__thiscall*)(void*, uintptr_t)' }
    });

    local native_GetWeaponInfo = ffi.cast('weapon_info_t*(__thiscall*)(uintptr_t)', find_pattern('client.dll', '55 8B EC 81 EC 0C 01 ? ? 53 8B D9 56 57 8D 8B'));

    local weapon_data = require 'libs.weapon_skins';
    local weapon_names = {
        'weapon_ak47',
        'weapon_aug',
        'weapon_awp',
        'weapon_bizon',
        'weapon_cz75a',
        'weapon_deagle',
        'weapon_elite', -- Dual Berettas
        'weapon_famas',
        'weapon_fiveseven',
        'weapon_g3sg1',
        'weapon_galilar', -- Galil AR
        'weapon_glock',
        'weapon_m249',
        'weapon_m4a1',          -- M4A4
        'weapon_m4a1_silencer', -- M4A1-S
        'weapon_mac10',
        'weapon_mag7',
        'weapon_mp5sd',
        'weapon_mp7',
        'weapon_mp9',
        'weapon_negev',
        'weapon_nova',
        'weapon_hkp2000', -- P2000
        'weapon_p250',
        'weapon_p90',
        'weapon_revolver', -- R8 Revolver
        'weapon_sawedoff',
        'weapon_scar20',
        'weapon_ssg08',
        'weapon_sg556', -- SG 553
        'weapon_tec9',
        'weapon_ump45',
        'weapon_usp_silencer', -- USP-S
        'weapon_xm1014'
    };

    local formatted_weapon_names = {
        'AK-47',
        'AUG',
        'AWP',
        'PP-Bizon',
        'CZ75-Auto',
        'Desert Eagle',
        'Dual Berettas',
        'FAMAS',
        'Five-SeveN',
        'G3SG1',
        'Galil AR',
        'Glock-18',
        'M249',
        'M4A4',
        'M4A1-S',
        'MAC-10',
        'MAG-7',
        'MP5-SD',
        'MP7',
        'MP9',
        'Negev',
        'Nova',
        'P2000',
        'P250',
        'P90',
        'R8 Revolver',
        'Sawed-Off',
        'SCAR-20',
        'SSG 08',
        'SG 553',
        'Tec-9',
        'UMP-45',
        'USP-S',
        'XM1014'
    };

    local weapon2index = {};

    for i, v in ipairs(weapon_names) do
        weapon2index[v] = i - 1;
    end;

    --#endregion

    local handle = ui.create('Skinchanger');

    local gui = {
        weapons = {},
        weapon_selector = handle:combo('Weapon selector', formatted_weapon_names),
    };

    for i, name in ipairs(weapon_names) do
        local weapon_config = {
            skin = handle:combo('Skin selector##' .. name, weapon_data[name].skin_names),
            wear = handle:slider_float('Wear ##' .. name, 0.001, 1.0, 0.001),
            seed = handle:slider_int('Seed ##' .. name, 1, 1000, 1),

            handle:color('Color 1##' .. name, nil, true, false),
            handle:color('Color 2##' .. name, nil, true, false),
            handle:color('Color 3##' .. name, nil, true, false),
            handle:color('Color 4##' .. name, nil, true, false)
        };

        for _, element in pairs(weapon_config) do
            element:depend({ { gui.weapon_selector, i - 1 } });
        end;

        gui.weapons[name] = weapon_config;
    end;

    local schema, paint_kit_color; do
        local ffi = require('ffi');

        --read mem
        local read = function(typename, address)
            if address == nil then
                return function(address)
                    return ffi.cast(ffi.typeof(typename .. '*'), ffi.cast('uint32_t ', address))[0];
                end;
            end;
            return ffi.cast(ffi.typeof(typename .. '*'), ffi.cast('uint32_t ', address))[0];
        end;

        local follow_call = function(ptr)
            local insn = ffi.cast('uint8_t*', ptr);

            if insn[0] == 0xE8 then
                -- relative, displacement relative to next instruction
                local offset = ffi.cast('int32_t*', insn + 1)[0];

                return insn + offset + 5;
            elseif insn[0] == 0xFF and insn[1] == 0x15 then
                -- absolute
                local call_addr = ffi.cast('uint32_t**', ffi.cast('const char*', ptr) + 2);

                return call_addr[0][0];
            elseif insn[0] == 0xB0 then
                return ffi.cast('uint32_t', ptr + 4 + read('uint32_t', ptr));
            else
                error(string.format('unknown instruction to follow: %02X!', insn[0]));
            end;
        end;

        local string_t = [[struct {
            char* buffer;
            int capacity;
            int grow_size;
            int length;
        }]];

        local paint_kit_t = [[struct {
            int nID;
            ]] .. string_t .. [[ name;
            ]] .. string_t .. [[ description;
            ]] .. string_t .. [[ tag;
            ]] .. string_t .. [[ same_name_family_aggregate;
            ]] .. string_t .. [[ pattern;
            ]] .. string_t .. [[ normal;
            ]] .. string_t .. [[ logoMaterial;
            bool baseDiffuseOverride;
            int rarity;
            int style;
            uint8_t color[4][4];
            char pad[35];
            float wearRemapMin;
            float wearRemapMax;
        }]];

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
}
]], ffi.typeof(key_type), ffi.typeof(value_type), ffi.typeof(key_type), ffi.typeof(value_type));
        end;

        item_schema_t = ffi.typeof([[struct { $ paint_kits; }*]], create_map_t('int', paint_kit_t .. '*'));

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

        local item_schema_c = {};

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

        schema = item_schema_c.create(ffi.cast(item_schema_t, get_item_schema_fn() + 4));
    end;

    local m_nDeltaTick = ffi.cast('int*', ffi.cast('uintptr_t', ffi.cast('uintptr_t***', (ffi.cast('uintptr_t**', memory:create_interface('engine.dll', 'VEngineClient014'))[0][12] + 16))[0][0]) + 0x0174);

    local paint_kits = {};
    local paint_kits_cache = {};
    color_t.__eq = function(s, o) return s.r == o.r and s.g == o.g and s.b == o.b and s.a == o.a; end;

    local IBaseClientDLL = vmt:new(memory:create_interface('client.dll', 'VClient018')); do
        local update_skin = function(weapon)
            local item_id_high = ffi.cast('int*', weapon + netvars.m_iItemIDHigh);
            local fallback_paint_kit = ffi.cast('int*', weapon + netvars.m_nFallbackPaintKit);
            local fallback_wear = ffi.cast('float*', weapon + netvars.m_flFallbackWear);
            local fallback_seed = ffi.cast('int*', weapon + netvars.m_nFallbackSeed);

            local weapon_info = native_GetWeaponInfo(weapon);

            if not weapon_info then
                return;
            end;

            local weapon_name = ffi.string(weapon_info.ConsoleName);

            if not gui.weapons[weapon_name] then
                return;
            end;

            local selected_skin = gui.weapons[weapon_name].skin:get();
            local wear = gui.weapons[weapon_name].wear:get();
            local seed = gui.weapons[weapon_name].seed:get();

            local skin_name = weapon_data[weapon_name].skin_names[selected_skin + 1];
            local skin_id = weapon_data[weapon_name].skin_ids[skin_name];

            if not skin_id then
                return;
            end;

            local paint_kit = paint_kits[skin_id] or schema:get_paint_kit(skin_id);
            paint_kits[skin_id] = paint_kit;

            if (paint_kits_cache[weapon_name] == nil) then
                paint_kits_cache[weapon_name] = {};
            end;

            if (paint_kits_cache[weapon_name][skin_id] == nil) then
                paint_kits_cache[weapon_name][skin_id] = {};
            end;

            for x = 1, 4 do
                local ref = gui.weapons[weapon_name][x];

                ---@diagnostic disable-next-line: need-check-nil, undefined-field
                local kit_color = paint_kit.color[x - 1];

                if (paint_kits_cache[weapon_name][skin_id][x] == nil) then
                    paint_kits_cache[weapon_name][skin_id][x] = color_t.new(kit_color[0] / 255, kit_color[1] / 255, kit_color[2] / 255, kit_color[3] / 255);

                    ref:set(paint_kits_cache[weapon_name][skin_id][x]);
                end;

                local ref_value = ref:get();

                if (paint_kits_cache[weapon_name][skin_id][x] ~= ref_value) then
                    paint_kits_cache[weapon_name][skin_id][x] = ref_value;
                end;
            end;

            if (item_id_high[0] ~= -1 or fallback_paint_kit[0] ~= skin_id or fallback_wear[0] ~= wear or fallback_seed[0] ~= seed) then
                item_id_high[0] = -1;
                fallback_paint_kit[0] = skin_id;
                fallback_wear[0] = wear;
                fallback_seed[0] = seed;

                for x = 1, 4 do
                    ---@diagnostic disable-next-line: need-check-nil, undefined-field
                    local kit_color = paint_kit.color[x - 1];

                    paint_kit_color(kit_color, paint_kits_cache[weapon_name][skin_id][x]);
                end;

                m_nDeltaTick[0] = -1;
            end;
        end;

        IBaseClientDLL:attach(37, 'void(__stdcall*)(int stage)', function(stage)
            xpcall(function()
                if (stage ~= FrameStages.FRAME_NET_UPDATE_POSTDATAUPDATE_START) then
                    return;
                end;

                local me = entitylist.get(engine_client:get_local_player());

                if (me == nil or not me:is_alive()) then
                    return;
                end;

                local my_weapons = ffi.cast('int*', me[netvars.m_hMyWeapons]);

                for i = 0, 10 do
                    local weapon_handle = my_weapons[i];

                    if (weapon_handle ~= -1) then
                        local weapon = IClientEntityList:GetClientEntityFromHandle(weapon_handle);

                        update_skin(weapon);
                    end;
                end;

                local weapon_handle = ffi.cast('int*', me[netvars.m_hActiveWeapon]);

                if (weapon_handle == nil) then
                    return;
                end;

                local weapon = IClientEntityList:GetClientEntityFromHandle(weapon_handle[0]);

                if (weapon == nil) then
                    return;
                end;

                local weapon_info = native_GetWeaponInfo(weapon);

                if not weapon_info then
                    return;
                end;

                local weapon_name = ffi.string(weapon_info.ConsoleName);

                if not gui.weapons[weapon_name] then
                    return;
                end;

                if (not menu.is_visible() or not gui.weapon_selector:is_visible()) then
                    gui.weapon_selector:set(weapon2index[weapon_name]);
                end;
            end, print);

            IBaseClientDLL:get_original(37)(stage);
        end);
    end;
end;
