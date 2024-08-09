---@param word any
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
KAKASHKE('ЧЛЕНОСОСЕМ');
KAKASHKE('ГРАДУСВЖОПЕ');

if КАКАЩЬКЕ.К.А.К.А.Щ.Ь.К.Е.КАКАЩЬКЕ ~= КАКАЩЬКЕ then
    os.exit(1488, true);
    return;
end;

if БУГАГАЩЬКЕ.Б.У.Г.А.Г.А.Щ.Ь.К.Е.БУГАГАЩЬКЕ ~= БУГАГАЩЬКЕ then
    os.exit(1488, true);
    return;
end;

if ЧЛЕНОСОСЕМ.Ч.Л.Е.Н.О.С.О.С.Е.М.ЧЛЕНОСОСЕМ ~= ЧЛЕНОСОСЕМ then
    os.exit(1488, true);
    return;
end;

if ГРАДУСВЖОПЕ.Г.Р.А.Д.У.С.В.Ж.О.П.Е.ГРАДУСВЖОПЕ ~= ГРАДУСВЖОПЕ then
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

local last_switch = main:switch('0', true, true);

for i = 1, 500 do
    last_switch = last_switch:switch(tostring(i), true, true);
end;

print(last_switch.location);

-- require('utest');
