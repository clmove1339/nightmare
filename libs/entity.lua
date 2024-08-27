require 'libs.enums';
local memory = require 'libs.memory';

function entity_t:is_alive()
    return self and ffi.cast('char*', self[netvars.m_lifeState])[0] == 0;
end;

function entity_t:get_velocity()
    local m_vecVelocity = ffi.cast('float*', self[netvars.m_vecVelocity]);
    return vec3_t.new(
        m_vecVelocity[0],
        m_vecVelocity[1],
        m_vecVelocity[2]
    );
end;

---@return integer
function entity_t:get_team()
    return ffi.cast('int*', self[netvars.m_iTeamNum])[0];
end;

function entitylist.from_handle(handle)
    return IClientEntityList:GetClientEntityFromHandle(handle);
end;

function entity_t:get_active_weapon()
    local m_hActiveWeapon = ffi.cast('int*', self[netvars.m_hActiveWeapon]);
    local weapon = entitylist.from_handle(m_hActiveWeapon[0]);

    if weapon ~= nil and weapon ~= -1 then
        local idx = ffi.cast('int*', weapon + 0x64)[0];

        return entitylist.get(idx);
    end;
end;

function entity_t:can_fire()
    local weapon = self:get_active_weapon();
    local servertime = ffi.cast('int*', self[netvars.m_nTickBase])[0] * globals.interval_per_tick;

    local m_flNextPrimaryAttack = ffi.cast('float*', weapon[netvars.m_flNextPrimaryAttack])[0];

    if ffi.cast('float*', self[netvars.m_flNextAttack])[0] > servertime then
        return false;
    end;

    return m_flNextPrimaryAttack <= servertime;
end;

function entity_t:get_eye_position()
    local m_vecViewOffset = ffi.cast('float*', self[netvars.m_vecViewOffset]);

    return self:get_origin() + vec3_t.new(m_vecViewOffset[0], m_vecViewOffset[1], m_vecViewOffset[2]);
end;

local StudioHitboxSet = ffi.typeof('StudioHitboxSet*');
local StudioBbox = ffi.typeof('StudioBbox*');
local native_get_poseparams = ffi.cast('pose_parameters_t*(__thiscall*)(void*, int)', find_pattern('client.dll', '55 8B EC 8B 45 08 57 8B F9 8B 4F 04 85 C9 75 15'));
local native_GetModel = memory:get_vfunc('engine.dll', 'VModelInfoClient004', 1, 'void*(__thiscall*)(void*, int)');
local native_GetStudioModel = memory:get_vfunc('engine.dll', 'VModelInfoClient004', 32, 'StudioHdr*(__thiscall*)(void*, void*)');
local native_GetPlayerInfo = memory:get_vfunc('engine.dll', 'VEngineClient014', 8, 'bool(__thiscall*)(void*, int, void*)');
local native_GetWeaponInfo = ffi.cast('weapon_info_t*(__thiscall*)(uintptr_t)', find_pattern('client.dll', '55 8B EC 81 EC 0C 01 ? ? 53 8B D9 56 57 8D 8B'));

function entity_t:get_weapon_info()
    return native_GetWeaponInfo(ffi.cast('uintptr_t*', self[0])[0]);
end;

function entity_t:is_grenade()
    local weapon_class = self:get_class_name():lower();

    if weapon_class:find('nade') then
        return true;
    end;

    return false;
end;

function entity_t:get_player_info()
    local player_info_t_ctype = ffi.new('player_info_t');
    local index = self:get_index();

    native_GetPlayerInfo(index, player_info_t_ctype);

    local player_info =
    {
        [0] = player_info_t_ctype,

        xuid = { low = player_info_t_ctype.xuidlow, high = player_info_t_ctype.xuidhigh },
        name = ffi.string(player_info_t_ctype.name),
        userid = player_info_t_ctype.userid,
        fake_player = player_info_t_ctype.fake_player,
        is_hltv = player_info_t_ctype.is_hltv,
        custom_files = player_info_t_ctype.custom_files,
        files_downloaded = player_info_t_ctype.files_downloaded
    };

    return player_info;
end;

function entity_t:get_studio_hdr()
    local studio_hdr = ffi.cast('void**', self[0x2950])[0];

    return studio_hdr;
end;

function entity_t:get_pose_params(index)
    local studio_hdr = self:get_studio_hdr();

    local params = native_get_poseparams(studio_hdr, index);

    return params;
end;

function entity_t:set_pose_params(index, m_start, m_end, m_state)
    local params = self:get_pose_params(index);

    local state = m_state or ((m_start + m_end) / 2);
    params.m_flStart, params.m_flEnd, params.m_flState = m_start, m_end, state;
end;

function entity_t:restore_pose_params()
    self:set_pose_params(0, -180, 180);
    self:set_pose_params(12, -90, 90);
    self:set_pose_params(6, 0, 1, 0);
    self:set_pose_params(7, -180, 180);
end;

function entity_t:get_bone_matrix(bone_index)
    local pointer = IClientEntityList:GetClientEntity(self:get_index());

    local bone_matrix = ffi.cast('float*', ffi.cast('uintptr_t*', pointer + 0x26A8)[0] + 0x30 * bone_index);

    return bone_matrix;
end;

function entity_t:get_hitbox_studio_bbox(hitboxes)
    local m_nModelIndex = ffi.cast('int*', self[netvars.m_nModelIndex])[0];
    local m_nHitboxSet = ffi.cast('int*', self[netvars.m_nHitboxSet])[0];

    local pModel = native_GetModel(m_nModelIndex);
    if pModel == nil then
        return nil;
    end;

    local pStudioHdr = native_GetStudioModel(pModel);
    if pStudioHdr == nil then
        return nil;
    end;

    local pHitboxSet = ffi.cast(StudioHitboxSet, ffi.cast('uintptr_t', pStudioHdr) + pStudioHdr.hitboxSetIndex) + m_nHitboxSet;

    local result = {}; for _, v in ipairs(hitboxes) do
        result[v % pHitboxSet.numHitboxes] = ffi.cast(StudioBbox, ffi.cast('uintptr_t', pHitboxSet) + pHitboxSet.hitboxIndex) + v % pHitboxSet.numHitboxes;
    end;

    return result;
end;

local function vector_transform(vector, matrix)
    return vec3_t.new(
        vector.x * matrix[0] + vector.y * matrix[1] + vector.z * matrix[2] + matrix[3],
        vector.x * matrix[4] + vector.y * matrix[5] + vector.z * matrix[6] + matrix[7],
        vector.x * matrix[8] + vector.y * matrix[9] + vector.z * matrix[10] + matrix[11]
    );
end;

function entity_t:get_hitbox_position(hitbox_index)
    local hitboxStudioBbox = self:get_hitbox_studio_bbox({ hitbox_index });
    if not hitboxStudioBbox then
        return;
    end;

    hitboxStudioBbox = hitboxStudioBbox[hitbox_index];
    local boneMatrix = self:get_bone_matrix(hitboxStudioBbox.bone);

    if boneMatrix == nil then
        return nil;
    end;

    local min, max = vector_transform(hitboxStudioBbox.bbMin, boneMatrix), vector_transform(hitboxStudioBbox.bbMax, boneMatrix);
    local center = (min + max) * .5;

    return center;
end;

---Checks whether the entity can be seen by the target
---@param target entity_t
---@return boolean
function entity_t:is_visible(target)
    if not (target and target:is_alive()) then
        return false;
    end;

    local mask = 0x46004003;
    local view_origin = target:get_eye_position();

    for i = 0, 18 do
        local origin = self:get_hitbox_position(i);

        if origin then
            local trace = engine.trace_line(view_origin, origin, target, mask);

            if trace.fraction > .9 then
                return true;
            end;
        end;
    end;

    return false;
end;
