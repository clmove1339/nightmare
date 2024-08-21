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

require('global');

local ui = require('ui');
local memory = require('memory');

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-Aim');

    antiaim.builder = {}; do
        local states_names = { 'Default', 'Stand', 'Run', 'Walk', 'Crouch', 'In Air' };
        local information = {};
        local group, builder = handle:switch('Builder', false, true);
        local states = group:combo('State', states_names, 0);

        for i, state in ipairs(states_names) do
            information[state] = {
                yaw_offset = group:slider_int(state .. ' - Yaw offset', -180, 180, 0)
            };

            for _, element in pairs(information[state]) do
                element:depend({ { states, i - 1 } });
            end;
        end;
    end;
end;
