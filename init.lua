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

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-Aim');

    antiaim.builder = {}; do
        local states_names = { 'Default', 'Run', 'Walk', 'Crouch', 'In Air' };
        local information = {};
        local group = handle:switch('Builder', false, true);

        for _, state in ipairs(states_names) do
            information[state] = {};
        end;

        local states = group:combo('State', states_names, 0);

        states:depend({

        });
    end;
end;
