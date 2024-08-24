require 'libs.enums';

function entity_t:is_alive()
    return self and ffi.cast('char*', self[netvars.m_lifeState])[0] == 0;
end;
