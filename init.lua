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
local subscription_level = 1;

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-Aim');

    antiaim.builder = {}; do
        local states = { 'Default', 'Run', 'Walk', 'Crouch', 'In Air' };
        local information = {};
        local group = handle:switch('Builder', false, true);

        for _, state in ipairs(states) do
            information[state] = {};
        end;

        group:combo('State', states, 0);

        --
    end;
end;
