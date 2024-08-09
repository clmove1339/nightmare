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

local A = main:switch('A', true, true);
local B = misc:switch('B', true, true);

local slider_a = A:slider_int('Some slider', 0, 100, 0);
local BA = B:switch('BA', false, true);

BA:button('Поцеловать никсера', function()
    print('Поцеловал никсера');
end);

slider_a:set(100);

A:combo('Some combo', { '1', '2', '3' });

require('utest');
