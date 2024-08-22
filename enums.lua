netvars = {
    m_lifeState = engine.get_netvar_offset('DT_BasePlayer', 'm_lifeState'),
    m_hActiveWeapon = engine.get_netvar_offset('DT_BaseCombatCharacter', 'm_hActiveWeapon'),
    m_hMyWeapons = engine.get_netvar_offset('DT_BaseCombatCharacter', 'm_hMyWeapons'),
    m_iItemIDHigh = engine.get_netvar_offset('DT_EconEntity', 'm_iItemIDHigh'),
    m_nFallbackPaintKit = engine.get_netvar_offset('DT_EconEntity', 'm_nFallbackPaintKit'),
    m_flFallbackWear = engine.get_netvar_offset('DT_EconEntity', 'm_flFallbackWear'),
    m_nFallbackSeed = engine.get_netvar_offset('DT_EconEntity', 'm_nFallbackSeed'),
    m_fFlags = engine.get_netvar_offset('DT_BasePlayer', 'm_fFlags'),
    m_flDuckAmount = engine.get_netvar_offset('DT_BasePlayer', 'm_flDuckAmount'),
};

FrameStages = {
    FRAME_UNDEFINED = -1,
    FRAME_START = 0,
    FRAME_NET_UPDATE_START = 1,
    FRAME_NET_UPDATE_POSTDATAUPDATE_START = 2,
    FRAME_NET_UPDATE_POSTDATAUPDATE_END = 3,
    FRAME_NET_UPDATE_END = 4,
    FRAME_RENDER_START = 5,
    FRAME_RENDER_END = 6
};

nixware = {
    ['Movement'] = {
        ['Anti aim'] = {
            enabled = menu.find_check_box('Enabled', 'Movement/Anti aim'),
            pitch = menu.find_combo_box('Pitch', 'Movement/Anti aim'),
            base_yaw = menu.find_combo_box('Base yaw', 'Movement/Anti aim'),
            yaw_offset = menu.find_slider_int('Yaw offset', 'Movement/Anti aim'),
            yaw_modifier = menu.find_combo_box('Yaw modifier', 'Movement/Anti aim'),
            yaw_modifier_offset = menu.find_slider_int('Yaw modifier offset', 'Movement/Anti aim'),
            yaw_desync = menu.find_combo_box('Yaw desync', 'Movement/Anti aim'),
            desync_inverter = menu.find_key_bind('Desync inverter', 'Movement/Anti aim'),
            yaw_desync_length = menu.find_slider_int('Yaw desync length', 'Movement/Anti aim'),
            extended_desync = menu.find_check_box('Extended desync [  ]', 'Movement/Anti aim'),
            roll_pitch = menu.find_slider_int('Pitch', 'Movement/Anti aim' .. '/Extended desync'),
            roll_yaw = menu.find_slider_int('Roll', 'Movement/Anti aim' .. '/Extended desync')
        },
        ['Movement'] = {
            fast_duck = menu.find_check_box('Fast duck', 'Movement/Movement'),
            fake_duck = menu.find_check_box('Fake duck', 'Movement/Movement'),
            fake_duck_bind = menu.find_key_bind('Fake duck', 'Movement/Movement'),
            edge_jump = menu.find_check_box('Edge jump', 'Movement/Movement'),
            edge_jump_bind = menu.find_key_bind('Edge jump', 'Movement/Movement'),
            accurate_walk = menu.find_check_box('Accurate walk', 'Movement/Movement'),
            accurate_walk_bind = menu.find_key_bind('Accurate walk', 'Movement/Movement'),
            auto_peek = menu.find_check_box('Auto peek [  ]', 'Movement/Movement'),
            auto_peek_bind = menu.find_key_bind('Auto peek', 'Movement/Movement'),
            retreat_options = menu.find_multi_combo_box('Retreat on', 'Movement/Movement/Auto peek'),
            auto_peek_color = menu.find_color_picker('Color', 'Movement/Movement/Auto peek'),
            moving_color = menu.find_color_picker('Moving color', 'Movement/Movement/Auto peek'),
            bunnyhop = menu.find_check_box('Bunnyhop', 'Movement/Movement'),
            auto_strafer = menu.find_check_box('Auto strafer [  ]', 'Movement/Movement'),
            smooth_amount = menu.find_slider_int('Smooth amount', 'Movement/Movement/Auto strafer'),
            leg_movement = menu.find_combo_box('Leg movement', 'Movement/Movement'),
        },
        ['Fakelag'] = {
            limit = menu.find_slider_int('Limit', 'Movement/Fakelag'),
        }
    }
};
