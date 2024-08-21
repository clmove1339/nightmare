do
    local import = require;

    require = function(modname)
        local success, module = pcall(import, modname);

        if success then
            return module;
        end;

        modname = string.format('nightmare.%s', modname);

        return import(modname);
    end;
end;

require 'nixware';
require 'global';

local ui = require 'ui';
local memory = require 'memory';

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-Aim');
    local enable = handle:switch('Enabled', false);

    antiaim.builder = {}; do
        local states_names = { 'Default', 'Standing', 'Running', 'Walking', 'Crouching', 'Sneaking', 'In Air', 'In Air & Crouching' };
        local information = {};
        local state_selector = handle:combo('State', states_names, 0);

        state_selector:depend({ { enable, true } });

        local function setup_state(state, index)
            local state_info = {
                override = handle:switch('Override ' .. state, state == 'Default'),
                pitch = handle:combo('Pitch##' .. state, { 'None', 'Down', 'Fake down', 'Fake up' }, 1),
                base_yaw = handle:combo('Base yaw##' .. state, { 'Local view', 'Static', 'At targets' }, 2),
                yaw_offset = handle:slider_int('Yaw offset##' .. state, -180, 180, 0),
                yaw_modifier = handle:combo('Yaw modifier##' .. state, { 'None', 'Center', 'Offset', 'Random', '3-Way', '5-Way' }, 0),
                yaw_modifier_offset = handle:slider_int('Yaw modifier offset##' .. state, -180, 180, 0),
                yaw_desync = handle:combo('Yaw desync##' .. state, { 'None', 'Static', 'Jitter', 'Random Jitter' }),
                yaw_desync_length = handle:slider_int('Yaw desync length', 0, 60, 0)
            };

            for element_name, element in pairs(state_info) do
                element:depend({ { enable, true }, { state_selector, index - 1 } });

                if element_name == 'override' and state == 'Default' then
                    element:depend({ { enable, true }, { state_selector, index - 1 }, false });
                end;
            end;

            information[state] = state_info;
        end;

        for i, state in ipairs(states_names) do
            setup_state(state, i);
        end;
    end;
end;

local rage = {}; do
    ---@private
    local handle = ui.create('Rage');

    handle:combo('Resolver Type', {
        'Off',
        'Default',
        'Extended',
        'SISKI MASISKI'
    });
end;
