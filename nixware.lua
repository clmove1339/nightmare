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
