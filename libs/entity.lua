require 'libs.enums';
require 'libs.interfaces';

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
    return ffi.cast('int*', me[netvars.m_iTeamNum])[0];
end;

function entitylist.from_handle(handle)
    return IClientEntityList:GetClientEntityFromHandle(handle);
end;

function entity_t:get_active_weapon()
    local m_hActiveWeapon = ffi.cast('int*', self[netvars.m_hActiveWeapon]);
    local weapon = entitylist.from_handle(m_hActiveWeapon[0]);

    return weapon;
end;

function entity_t:can_fire()
    local weapon = self:get_active_weapon();
    local servertime = ffi.cast('int*', self[netvars.m_nTickBase])[0] * globals.interval_per_tick;

    return ffi.cast('float*', weapon + netvars.m_flNextPrimaryAttack)[0] <= servertime;
end;

function entity_t:get_eye_position()
    local m_vecViewOffset = ffi.cast('float*', self[netvars.m_vecViewOffset]);

    return self:get_origin() + vec3_t.new(m_vecViewOffset[0], m_vecViewOffset[1], m_vecViewOffset[2]);
end;

function entity_t:is_visible()
    local lp = entitylist.get_local_player();
    if not lp then return false; end;

    local trace = engine.trace_line(lp:get_eye_position(), self:get_origin(), lp, 0x46004003);

    return trace.fraction > .9;
end;
