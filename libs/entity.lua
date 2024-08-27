require 'libs.enums';

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
