do
    local import = require;

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

local aimbot = {}; do
    ---@private
    local handle = ui.create('Aimbot');

    handle:combo('Resolver Type', {
        'Off',
        'Default',
        'Extended'
    });
end;

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-aimbot');
    local enable = handle:switch('Enabled', false);
    local sub_handle = handle:combo('Anti-aimbot part:', { 'General', 'Settings' });

    sub_handle:depend({ { enable, true } });

    antiaim.general = {}; do
        local features = handle:multicombo('Features', { 'Anti-backstab', 'Manual anti-aim' }, {});

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

    local states = { 'Default', 'Standing', 'Running', 'Walking', 'Crouching', 'Sneaking', 'In Air', 'In Air & Crouching' };
    local netvars = {
        m_fFlags = engine.get_netvar_offset('DT_BasePlayer', 'm_fFlags'),
        m_flDuckAmount = engine.get_netvar_offset('DT_BasePlayer', 'm_flDuckAmount'),
    }; -- мне абсолютно поебать что оно возможно не там где надо находится

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

        local function setup(cmd)
            nixware['Movement']['Anti aim'].enabled:set(enable:get());

            local statement = information[antiaim:get_statement(cmd)].override:get() and antiaim:get_statement(cmd) or 'Default';
            local settings = information[statement];

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
