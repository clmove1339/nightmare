function KAKASHKE(word)
    _G[word] = {};

    local current = _G[word];

    for char in word:gmatch('..') do
        if not current[char] then
            current[char] = {};
        end;

        current = current[char];
    end;

    current[word] = _G[word];
end;

KAKASHKE('КАКАЩЬКЕ');
KAKASHKE('БУГАГАЩЬКЕ');

if КАКАЩЬКЕ.К.А.К.А.Щ.Ь.К.Е.КАКАЩЬКЕ ~= КАКАЩЬКЕ then
    os.exit(1488, true);
    return;
end;

if БУГАГАЩЬКЕ.Б.У.Г.А.Г.А.Щ.Ь.К.Е.БУГАГАЩЬКЕ ~= БУГАГАЩЬКЕ then
    os.exit(1488, true);
    return;
end;

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
local misc = ui.create('Misc');

main:switch('КАКАЩКЕ', true, true);
misc:switch('БУГАГАЩЬКЕ', true, true);
