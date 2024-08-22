do
    local import = require;

    ---@param modname string
    ---@return any
    require = function(modname)
        local success, module = pcall(import, modname);

        if not success then
            module = import(string.format('nightmare.%s', modname));
        end;

        return module;
    end;
end;

require 'nixware';
require 'global';

local ui = require 'ui';
local memory = require 'memory';
local utils = require 'utils';
local engine_client = require 'engine_client';
local vmt = require 'vmt';
local inspect = require 'inspect';

local aimbot = {}; do
    ---@private
    local handle = ui.create('Aimbot');

    local e = handle:switch('ENABLE CUSTOM_RESOZOLVER');

    handle:combo('Resolver Type', {
        'Off',
        'Default',
        'Extended'
    });
end;

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-aimbot');
    local enable = handle:switch('Enabled'); -- Ебаный сын никсера блять
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
    local netvars = {
        m_fFlags = engine.get_netvar_offset('DT_BasePlayer', 'm_fFlags'),
        m_flDuckAmount = engine.get_netvar_offset('DT_BasePlayer', 'm_flDuckAmount'),
    }; -- мне абсолютно поебать что оно возможно не там где надо находится

    ---@param cmd user_cmd_t
    function antiaim:get_statement(cmd)
        local me = entitylist.get_local_player();

        if not me then
            return states[1];
        end;

        local flags = ffi.cast('int*', me[netvars.m_fFlags])[0];
        local duck_amount = ffi.cast('int*', me[netvars.m_flDuckAmount])[0];
        local velocity = math.floor(math.abs(cmd.forwardmove) + math.abs(cmd.sidemove));

        local is_fake_duck = menu.find_check_box('Fake duck', 'Movement/Movement'):get() and menu.find_key_bind('Fake duck', 'Movement/Movement'):is_active();

        local in_crouch = duck_amount > 0 or is_fake_duck;
        local in_air = bit.band(cmd.buttons, bit.lshift(1, 1)) == bit.lshift(1, 1) or bit.band(flags, bit.lshift(1, 0)) == 0;
        local in_speed = bit.band(cmd.buttons, bit.lshift(1, 17)) == bit.lshift(1, 17);
        local in_use = bit.band(cmd.buttons, 32) == 32;

        if in_use then
            return states[9];
        end;

        if in_air then
            return states[in_crouch and 8 or 7];
        end;

        if in_crouch then
            return states[velocity > 1.1 * 3.3 and 6 or 5];
        end;

        if velocity > 1.1 * 3.3 then
            return states[in_speed and 4 or 3];
        end;

        return states[2];
    end;

    antiaim.builder = {}; do
        local information = {};
        local state_selector = handle:combo('State', states, 0);

        state_selector:depend({ { enable, true }, { sub_handle, 1 } });

        local function setup_state(state, index)
            local state_info = {
                override = handle:switch('Override ' .. state, state == 'Default'),
                pitch = handle:combo('Pitch##' .. state, { 'None', 'Down', 'Fake down', 'Fake up' }, 1),
                base_yaw = handle:combo('Base yaw##' .. state, { 'Local view', 'Static', 'At targets' }, 2),
                yaw_offset = handle:slider_int('Yaw offset##' .. state, -180, 180, 180),
                yaw_modifier = handle:combo('Yaw modifier##' .. state, { 'None', 'Center', 'Offset', 'Random', '3-Way', '5-Way' }, 0),
                yaw_modifier_offset = handle:slider_int('Yaw modifier offset##' .. state, -180, 180, 0),
                yaw_desync = handle:combo('Yaw desync##' .. state, { 'None', 'Static', 'Jitter', 'Random Jitter' }),
                yaw_desync_length = handle:slider_int('Yaw desync length##' .. state, 0, 60, 0)
            };

            for element_name, element in pairs(state_info) do
                local is_default_state = state == 'Default';
                local is_override_checkbox = element_name == 'override';

                element:depend({ { enable, true }, { state_selector, index - 1 }, { sub_handle, 1 }, not (is_default_state and is_override_checkbox), (is_default_state or is_override_checkbox) and true or { state_info.override, true } });
            end;

            information[state] = state_info;
        end;

        for i, state in ipairs(states) do
            setup_state(state, i);
        end;

        local base_path = 'Movement/Anti aim';

        -- я для чего nixware таблицу делал пидор?
        -- чтобы ты опять взял и пукнул в код жиденько?
        -- неоЖИДанно и СВОевременно
        local elements = {
            pitch = menu.find_combo_box('Pitch', base_path),
            base_yaw = menu.find_combo_box('Base yaw', base_path),
            yaw_offset = menu.find_slider_int('Yaw offset', base_path),
            yaw_modifier = menu.find_combo_box('Yaw modifier', base_path),
            yaw_modifier_offset = menu.find_slider_int('Yaw modifier offset', base_path),
            yaw_desync = menu.find_combo_box('Yaw desync', base_path),
            yaw_desync_length = menu.find_slider_int('Yaw desync length', base_path),
        };

        local native_enabled = nixware['Movement']['Anti aim'].enabled:get();

        ---@param cmd user_cmd_t
        local function setup(cmd)
            nixware['Movement']['Anti aim'].enabled:set(enable:get());

            local state = antiaim:get_statement(cmd);
            state = information[state].override:get() and state or 'Default';

            local settings = information[state];

            -- Тут кароче пастроем бальшо функцый для лэгит аа

            for name, element in pairs(settings) do
                if name == 'override' then
                    goto continue;
                end;

                elements[name]:set(element:get());

                ::continue::
            end;
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

    -- и тут мне тоже абсолютно поебать, сами подравите как надо ( либо я как проснусь )
    local old_value = cvars.cam_idealdist:get_int();
    local camera_distance = handle:slider_int('3rd person distance', 30, 180, old_value);

    register_callback('paint', function()
        if camera_distance:get() ~= old_value then
            cvars.cam_idealdist:set_int(camera_distance:get());
        end;
    end);
end;

local skinchanger = {}; do
    --#region: Ponos deda
    local m_lifeState = engine.get_netvar_offset('DT_BasePlayer', 'm_lifeState');
    local m_hActiveWeapon = engine.get_netvar_offset('DT_BaseCombatCharacter', 'm_hActiveWeapon');
    local m_hMyWeapons = engine.get_netvar_offset('DT_BaseCombatCharacter', 'm_hMyWeapons');
    local m_iItemIDHigh = engine.get_netvar_offset('DT_EconEntity', 'm_iItemIDHigh');
    local m_nFallbackPaintKit = engine.get_netvar_offset('DT_EconEntity', 'm_nFallbackPaintKit');
    local m_flFallbackWear = engine.get_netvar_offset('DT_EconEntity', 'm_flFallbackWear');
    local m_nFallbackSeed = engine.get_netvar_offset('DT_EconEntity', 'm_nFallbackSeed');

    local IClientEntityList = memory:interface('client', 'VClientEntityList003', {
        GetClientEntity = { 3, 'uintptr_t(__thiscall*)(void*, int)' },
        GetClientEntityFromHandle = { 4, 'uintptr_t(__thiscall*)(void*, uintptr_t)' }
    });

    function entity_t:is_alive()
        return ffi.cast('char*', self[m_lifeState])[0] == 0;
    end;

    local native_GetWeaponInfo = ffi.cast('weapon_info_t*(__thiscall*)(uintptr_t)', find_pattern('client.dll', '55 8B EC 81 EC 0C 01 ? ? 53 8B D9 56 57 8D 8B'));

    local weapon_data = require 'weapon_skins';
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

    local weapon2index = {};

    for i, v in ipairs(weapon_names) do
        weapon2index[v] = i - 1;
    end;

    --#endregion

    local handle = ui.create('Skinchanger');

    local gui = {
        weapons = {},
        weapon_selector = handle:combo('Weapon selector', weapon_names),
    };

    for i, name in ipairs(weapon_names) do
        local weapon_config = {
            skin = handle:combo('Skin selector##' .. name, weapon_data[name].skin_names),
            wear = handle:slider_float('Wear ##' .. name, 0.001, 1.0, 0.001),
            seed = handle:slider_int('Seed ##' .. name, 1, 1000, 1),
        };

        for _, element in pairs(weapon_config) do
            element:depend({ { gui.weapon_selector, i - 1 } });
        end;

        gui.weapons[name] = weapon_config;
    end;

    local m_nDeltaTick = ffi.cast('int*', ffi.cast('uintptr_t', ffi.cast('uintptr_t***', (ffi.cast('uintptr_t**', memory:create_interface('engine.dll', 'VEngineClient014'))[0][12] + 16))[0][0]) + 0x0174);

    local IBaseClientDLL = vmt:new(memory:create_interface('client.dll', 'VClient018')); do
        local FrameStages = {
            FRAME_UNDEFINED = -1,
            FRAME_START = 0,
            FRAME_NET_UPDATE_START = 1,
            FRAME_NET_UPDATE_POSTDATAUPDATE_START = 2,
            FRAME_NET_UPDATE_POSTDATAUPDATE_END = 3,
            FRAME_NET_UPDATE_END = 4,
            FRAME_RENDER_START = 5,
            FRAME_RENDER_END = 6
        };

        local update_skin = function(weapon)
            local item_id_high = ffi.cast('int*', weapon + m_iItemIDHigh);
            local fallback_paint_kit = ffi.cast('int*', weapon + m_nFallbackPaintKit);
            local fallback_wear = ffi.cast('float*', weapon + m_flFallbackWear);
            local fallback_seed = ffi.cast('int*', weapon + m_nFallbackSeed);

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

            if (item_id_high[0] ~= -1 or fallback_paint_kit[0] ~= skin_id or fallback_wear[0] ~= wear or fallback_seed[0] ~= seed) then
                item_id_high[0] = -1;
                fallback_paint_kit[0] = skin_id;
                fallback_wear[0] = wear;
                fallback_seed[0] = seed;

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

                local my_weapons = ffi.cast('int*', me[m_hMyWeapons]);

                for i = 0, 10 do
                    local weapon_handle = my_weapons[i];

                    if (weapon_handle ~= -1) then
                        local weapon = IClientEntityList:GetClientEntityFromHandle(weapon_handle);

                        update_skin(weapon);
                    end;
                end;

                local weapon_handle = ffi.cast('int*', me[m_hActiveWeapon]);

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
