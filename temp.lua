local super_toss = {};

super_toss.active = false;

super_toss.check_active = function()
    super_toss.active = false;
    local me = entitylist.get_local_player();
    if not (me and me:is_alive()) then
        return;
    end;

    local m_MoveType = ffi.cast('int*', ffi.cast('uintptr_t', me[0]) + 0x25C)[0];

    if m_MoveType == 8 or m_MoveType == 9 then
        return;
    end;

    local weapon = me:get_active_weapon();

    local weapon_info = weapon:is_grenade();
    if weapon_info == nil then
        return;
    end;

    super_toss.active = true;
end;

ffi.cdef([[
    typedef struct {
        float x;
        float y;
        float z;
    } vector_t;
]]);

super_toss.ang_vec = function(ang)
    return vec3_t.new(
        math.cos(ang.x * math.pi / 180) * math.cos(ang.y * math.pi / 180),
        math.cos(ang.x * math.pi / 180) * math.sin(ang.y * math.pi / 180),
        -math.sin(ang.x * math.pi / 180)
    );
end;

super_toss.on_render = function()
    super_toss.check_active();
end;

super_toss.on_createmove = function(cmd)
    if not super_toss.active then
        return;
    end;

    local me = entity.get_local_player();
    if not (me and me:is_alive()) then
        return;
    end;

    local weapon = me:get_player_weapon();
    if weapon == nil then
        return;
    end;

    local weapon_handle = ffi.cast('int*', me[netvars.m_hActiveWeapon]);
    if not weapon_handle then
        return;
    end;

    local weapon_from_penis = entitylist.from_handle(weapon_handle[0]);
    if not weapon_from_penis then
        return;
    end;

    local weapon_info = native_GetWeaponInfo(weapon_from_penis);
    if not weapon_info then
        return;
    end;

    local ang_throw = vector(cmd.viewangles.x, cmd.viewangles.y, 0);
    ang_throw.x = ang_throw.x - (90 - math.abs(ang_throw.x)) * 10 / 90;
    ang_throw = super_toss.ang_vec(ang_throw);

    local throw_strength = math.clamp(weapon.m_flThrowStrength, 0, 1);
    local fl_velocity = math.clamp(weapon_info.throw_velocity * 0.9, 15, 750);

    fl_velocity = fl_velocity * (throw_strength * 0.7 + 0.3);

    local my_velocity = ffi.cast('vector_t*', ffi.cast('uintptr_t', me[0]) + 0x94)[0];
    my_velocity = vec3_t.new(my_velocity.x, my_velocity.y, my_velocity.z);

    local vec_throw = (ang_throw * fl_velocity + my_velocity * 1.45);
    vec_throw = vec_throw:to_angle();

    local yaw_difference = cmd.viewangles.yaw - vec_throw.yaw;
    while yaw_difference > 180 do
        yaw_difference = yaw_difference - 360;
    end;
    while yaw_difference < -180 do
        yaw_difference = yaw_difference + 360;
    end;

    local pitch_difference = cmd.viewangles.pitch - vec_throw.pitch - 10;
    while pitch_difference > 90 do
        pitch_difference = pitch_difference - 45;
    end;

    while pitch_difference < -90 do
        pitch_difference = pitch_difference + 45;
    end;

    cmd.viewangles.yaw = cmd.viewangles.y + yaw_difference;
    cmd.viewangles.pitch = math.clamp(cmd.viewangles.pitch + pitch_difference, -89, 89);
end;

register_callback('paint', function()
    xpcall(super_toss.on_render, print);
end);
register_callback('create_move', function(cmd)
    xpcall(super_toss.on_createmove, print, cmd);
end);
