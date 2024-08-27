local memory = require 'libs.memory';

---@class CMaterial
---@field this IMaterial
local material_c = {}; do
    function material_c:get_name()
        return ffi.string(self.this:GetName());
    end;

    function material_c:get_texture_group_name()
        return ffi.string(self.this:GetTextureGroupName());
    end;

    ---@param clr color_t
    function material_c:set_color(clr)
        self.this:AlphaModulate(clr.a);
        self.this:ColorModulate(clr.r, clr.g, clr.b);
    end;

    ---@param alpha number
    function material_c:set_alpha(alpha)
        self.this:AlphaModulate(alpha);
    end;

    function material_c:is_error()
        return self.this:IsErrorMaterial();
    end;

    ---@param flag MATERIAL_VAR_FLAGS
    ---@return boolean
    function material_c:get_flag(flag)
        return self.this:GetMaterialVarFlag(flag);
    end;

    ---@param flag MATERIAL_VAR_FLAGS
    ---@param value boolean
    function material_c:set_flag(flag, value)
        self.this:SetMaterialVarFlag(flag, value);
    end;

    material_c.__index = material_c;
end;

local material_system = {}; do
    ---@private
    ---@return CMaterial
    local function init(material)
        return setmetatable({ this = IMaterial(material) }, material_c);
    end;

    ---@public
    ---@enum MATERIAL_VAR_FLAGS
    material_system.flags = {
        DEBUG                    = 1,
        NO_DEBUG_OVERRIDE        = 2,
        NO_DRAW                  = 4,
        USE_IN_FILLRATE_MODE     = 8,
        VERTEXCOLOR              = 16,
        VERTEXALPHA              = 32,
        SELFILLUM                = 64,
        ADDITIVE                 = 128,
        ALPHATEST                = 256,
        MULTIPASS                = 512,
        ZNEARER                  = 1024,
        MODEL                    = 2048,
        FLAT                     = 4096,
        NOCULL                   = 8192,
        NOFOG                    = 16384,
        IGNOREZ                  = 32768,
        DECAL                    = 65536,
        ENVMAPSPHERE             = 131072,
        NOALPHAMOD               = 262144,
        ENVMAPCAMERASPACE        = 524288,
        BASEALPHAENVMAPMASK      = 1048576,
        TRANSLUCENT              = 2097152,
        NORMALMAPALPHAENVMAPMASK = 4194304,
        NEEDS_SOFTWARE_SKINNING  = 8388608,
        OPAQUETEXTURE            = 16777216,
        ENVMAPMODE               = 33554432,
        SUPPRESS_DECALS          = 67108864,
        HALFLAMBERT              = 134217728,
        WIREFRAME                = 268435456,
        ALLOWALPHATOCOVERAGE     = 536870912,
        IGNORE_ALPHA_MODULATION  = 1073741824,
    };

    ---@param material number
    ---@return CMaterial
    function material_system:get_material(material)
        return init(IMaterialSystem:GetMaterial(material));
    end;

    ---@param name string
    ---@param texture_group_name? string
    ---@param complain? boolean
    ---@param complain_prefix? string
    ---@return CMaterial?
    function material_system:find_material(name, texture_group_name, complain, complain_prefix)
        complain = complain or false;
        complain_prefix = complain_prefix or nil;

        local material = IMaterialSystem:FindMaterial(name, texture_group_name, complain, complain_prefix);

        return init(material);
    end;

    ---@return number
    function material_system:first_material()
        return IMaterialSystem:FirstMaterial();
    end;

    ---@param material number
    ---@return number
    function material_system:next_material(material)
        return IMaterialSystem:NextMaterial(material);
    end;

    ---@return number
    function material_system:invalid_material()
        return IMaterialSystem:InvalidMaterial();
    end;

    ---@generic T
    ---@param fn fun(material: CMaterial): T?
    ---@return T[]
    function material_system:traverse(fn)
        local i = material_system:first_material();
        local out = {};

        while i ~= material_system:invalid_material() do
            local material = material_system:get_material(i);

            local result = fn(material);
            out[#out + 1] = result;

            i = material_system:next_material(i);
        end;

        return out;
    end;
end;

return material_system;
