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
require('kakashke');

local ui = require('ui');

local Rage = {}; do
    ---@private
    local handle = ui.create('Rage');
end;

local AntiAim = {}; do
    ---@private
    local handle = ui.create('Anti-Aim');
end;

local Visual = {}; do
    ---@private
    local handle = ui.create('Visual');
end;

local Misc = {}; do
    ---@private
    local handle = ui.create('Misc');
end;
