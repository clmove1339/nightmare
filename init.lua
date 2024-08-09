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

local ui = require('ui');
local main = ui.create('Main');

main:switch('КАКАЩКЕ', true, true);
