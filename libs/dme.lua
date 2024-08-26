local memory = require 'libs.memory';
local vmt = require 'libs.vmt';
local engine_client = require 'libs.engine_client';

ffi.cdef [[
    typedef float matrix3x4_t[3][4];

    typedef struct {
        float x, y, z;
    } vector_t;

    typedef struct {
        void*   fnHandle;
        char    szName[260];
        int     nLoadFlags;
        int     nServerCount;
        int     type;
        int     flags;
        float  vecMins[3];
        float  vecMaxs[3];
        float   radius;
        char    pad[0x1C];
    } model_t;

    typedef struct {
        vector_t origin;
        vector_t angles;
        char pad[4];
        void* pRenderable;
        const model_t* pModel;
        const matrix3x4_t* pModelToWorld;
        const matrix3x4_t* pLightingOffset;
        const vector_t* pLightingOrigin;
        int flags;
        int entity_index;
        int skin;
        int body;
        int hitboxset;
        unsigned short instance;
    } ModelRenderInfo_t;
]];

local IVRenderView = memory:interface('engine.dll', 'VEngineRenderView', {
    SetBlend = { 4, 'void(__thiscall*)(void*, float)' },
    GetBlend = { 5, 'float(__thiscall*)(void*)' },
});

local IVModelRender = vmt:new(memory:create_interface('engine.dll', 'VEngineModel016'));

IVModelRender:attach(21, 'void(__thiscall*)(void*, void*, void*, const ModelRenderInfo_t&, matrix3x4_t*)', function(edx, ecx, state, info, custom_bone_to_world)
    local o_fn = IVModelRender:get_original(21);
    local draw_original = true;

    xpcall(function()
        if (info.pModel == nil or info.entity_index ~= engine_client:get_local_player()) then
            return;
        end;

        local entity = entitylist.get(info.entity_index);

        if (entity == nil or not entity:is_alive() or entity:is_dormant()) then
            return;
        end;

        local model_name = ffi.string(info.pModel.szName);
    end, print);

    if (not draw_original) then
        return;
    end;

    o_fn(edx, ecx, state, info, custom_bone_to_world);
end);
