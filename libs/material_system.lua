-- Эта материал система просто поражает

local memory = require 'libs.memory';

local IMaterial = memory:class({
    -- fns
});

local material_c = {}; do

end;

local material_system = {}; do
    local function init(material)
        return setmetatable({ this = IMaterial(material) }, material_c);
    end;
end;

return material_system;
