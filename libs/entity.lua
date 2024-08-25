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
