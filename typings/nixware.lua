---@meta _
---@diagnostic disable: missing-return

---@class vec2_t
---@field x number
---@field y number
---@operator add(vec2_t): vec2_t
---@operator sub(vec2_t): vec2_t
---@operator mul(number): vec2_t
---@operator sub(number): vec2_t
---@operator unm(): vec2_t
---@operator len(): number

vec2_t = {};

---@param x number
---@param y number
---@return vec2_t
vec2_t.new = function(x, y) end;

---@class vec3_t
---@field x number
---@field y number
---@field z number
---@operator add(vec3_t): vec3_t
---@operator sub(vec3_t): vec3_t
---@operator mul(number): vec3_t
---@operator sub(number): vec3_t
---@operator unm(): vec3_t
---@operator len(): number

vec3_t = {};

---@param x number
---@param y number
---@param z number
---@return vec3_t
vec3_t.new = function(x, y, z) end;

---@class vec4_t
---@field x number
---@field y number
---@field z number
---@field w number

vec4_t = {};

---@param x number
---@param y number
---@param z number
---@param w number
---@return vec4_t
vec4_t.new = function(x, y, z, w) end;

---@class angle_t
---@field pitch number
---@field yaw number
---@field roll number

angle_t = {};

---@param pitch number
---@param yaw number
---@param roll number
---@return angle_t
angle_t.new = function(pitch, yaw, roll) end;

---@class color_t
---@field r number
---@field g number
---@field b number
---@field a number

color_t = {};

---@param r number
---@param g number
---@param b number
---@param a number
---@return color_t
color_t.new = function(r, g, b, a) end;

---@class entity_t
---@field [number] ffi.cdata*
entity_t = {};

---@return boolean
function entity_t:is_player() end;

---@return boolean
function entity_t:is_weapon() end;

---@return boolean
function entity_t:is_dormant() end;

---@return number
function entity_t:get_index() end;

---@return vec3_t
function entity_t:get_origin() end;

---@return number
function entity_t:get_class_id() end;

---@return string
function entity_t:get_class_name() end;

render = {};

---@return vec2_t
render.screen_size = function() end;

---@class font_t: number

---@param filename string
---@param size number
---@param flags? number
---@return font_t?
render.setup_font = function(filename, size, flags) end;

---@param text string
---@param font font_t
---@param size? number
---@return vec2_t?
render.calc_text_size = function(text, font, size) end;

---@param pos vec3_t
---@return vec2_t?
render.world_to_screen = function(pos) end;

---@param text string
---@param font font_t|0|1
---@param pos vec2_t
---@param color? color_t
---@param size? number
render.text = function(text, font, pos, color, size) end;

---@param from vec2_t
---@param to vec2_t
---@param color color_t
---@param thickness? number
render.line = function(from, to, color, thickness) end;

---@param from vec2_t
---@param to vec2_t
---@param color color_t
---@param rounding? number
---@param thickness? number
render.rect = function(from, to, color, rounding, thickness) end;

---@param from vec2_t
---@param to vec2_t
---@param color color_t
---@param rounding? number
render.rect_filled = function(from, to, color, rounding) end;

---@param from vec2_t
---@param to vec2_t
---@param col_upr_left color_t
---@param col_upr_right color_t
---@param col_bot_right color_t
---@param col_bot_left color_t
render.rect_filled_fade = function(from, to, col_upr_left, col_upr_right, col_bot_right, col_bot_left) end;

---@param pos vec2_t
---@param radius number
---@param segments number
---@param color color_t
---@param thickness? number
render.circle = function(pos, radius, segments, color, thickness) end;

---@param pos vec2_t
---@param radius number
---@param segments number
---@param color color_t
render.circle_filled = function(pos, radius, segments, color) end;

---@param pos vec2_t
---@param radius number
---@param color_in color_t
---@param color_out color_t
render.circle_fade = function(pos, radius, color_in, color_out) end;

---@param points vec2_t[]
---@param color color_t
render.filled_polygon = function(points, color) end;

---@param points vec2_t[]
---@param color color_t
render.poly_line = function(points, color) end;

---@param from vec2_t
---@param to vec2_t
---@param intersect_with_current_clip_rect? boolean
render.push_clip_rect = function(from, to, intersect_with_current_clip_rect) end;

render.pop_clip_rect = function() end;

---@param pos vec3_t
---@param radius number
---@param color color_t
---@param thickness? number
---@param normal? vec3_t
render.circle_3d = function(pos, radius, color, thickness, normal) end;

---@param pos vec3_t
---@param radius number
---@param color color_t
---@param normal? vec3_t
render.circle_filled_3d = function(pos, radius, color, normal) end;

---@param pos vec3_t
---@param radius number
---@param color_in color_t
---@param color_out color_t
---@param normal? vec3_t
render.circle_fade_3d = function(pos, radius, color_in, color_out, normal) end;

menu = {};

---@class check_box_t
check_box_t = {};

---@return boolean
function check_box_t:get() end;

---@param value boolean
function check_box_t:set(value) end;

---@param label string
---@param location string
---@param default_value? boolean
---@param context_location? string
---@return check_box_t
menu.add_check_box = function(label, location, default_value, context_location) end;

---@class slider_int_t
slider_int_t = {};

---@return number
function slider_int_t:get() end;

---@param value number
function slider_int_t:set(value) end;

---@param label string
---@param location string
---@param min number
---@param max number
---@param default_value? number
---@return slider_int_t
menu.add_slider_int = function(label, location, min, max, default_value) end;

---@class slider_float_t
slider_float_t = {};

---@return number
function slider_float_t:get() end;

---@param value number
function slider_float_t:set(value) end;

---@param label string
---@param location string
---@param min number
---@param max number
---@param default_value? number
---@return slider_float_t
menu.add_slider_float = function(label, location, min, max, default_value) end;

---@class combo_box_t
combo_box_t = {};

---@return number
function combo_box_t:get() end;

---@param value number
function combo_box_t:set(value) end;

---@param items string[]
function combo_box_t:set_items(items) end;

---@param label string
---@param location string
---@param items string[]
---@param default_value? number
---@return combo_box_t
menu.add_combo_box = function(label, location, items, default_value) end;

---@class multi_combo_box_t
multi_combo_box_t = {};

---@param index number
---@return boolean
function multi_combo_box_t:get(index) end;

---@param index number
---@param value boolean
function multi_combo_box_t:set(index, value) end;

---@param items string[]
function multi_combo_box_t:set_items(items) end;

---@param label string
---@param location string
---@param items string[]
---@param default_value? number[]
---@return multi_combo_box_t
menu.add_multi_combo_box = function(label, location, items, default_value) end;

---@class key_bind_t
key_bind_t = {};

---@return boolean
function key_bind_t:is_active() end;

---@return number
function key_bind_t:get_key() end;

---@return number
function key_bind_t:get_type() end;

---@return boolean
function key_bind_t:get_display_in_list() end;

---@param type number
function key_bind_t:set_type(type) end;

---@param key number
function key_bind_t:set_key(key) end;

---@param display_in_list boolean
function key_bind_t:set_display_in_list(display_in_list) end;

---@param label string
---@param location string
---@param show_label? boolean
---@param key? number
---@param type? number
---@param display_in_list? boolean
---@return key_bind_t
menu.add_key_bind = function(label, location, show_label, key, type, display_in_list) end;

---@class color_picker_t
color_picker_t = {};

---@return color_t
function color_picker_t:get() end;

---@param value color_t
function color_picker_t:set(value) end;

---@param label string
---@param location string
---@param show_label? boolean
---@param show_alpha? boolean
---@param default_value? color_t
---@return color_picker_t
menu.add_color_picker = function(label, location, show_label, show_alpha, default_value) end;

---@class button_t
button_t = {};

function button_t:execute() end;

---@param label string
---@param location string
---@param callback fun()
menu.add_button = function(label, location, callback) end;

---@param label string
---@param location string
---@return check_box_t
menu.find_check_box = function(label, location) end;

---@param label string
---@param location string
---@return slider_int_t
menu.find_slider_int = function(label, location) end;

---@param label string
---@param location string
---@return slider_float_t
menu.find_slider_float = function(label, location) end;

---@param label string
---@param location string
---@return combo_box_t
menu.find_combo_box = function(label, location) end;

---@param label string
---@param location string
---@return multi_combo_box_t
menu.find_multi_combo_box = function(label, location) end;

---@param label string
---@param location string
---@return key_bind_t
menu.find_key_bind = function(label, location) end;

---@param label string
---@param location string
---@return color_picker_t
menu.find_color_picker = function(label, location) end;

---@return vec4_t
menu.get_menu_rect = function() end;

---@return boolean
menu.is_visible = function() end;

menu.dump = function() end;

esp = {};

---@class esp_type
esp.enemy = {};
---@class esp_type
esp.local_player = {};
---@class esp_type
esp.team = {};

---@param bar_name string
---@param callback fun(entity: entity_t): number?
function esp.local_player.add_bar(bar_name, callback) end;

---@param text_name string
---@param preview_value string
---@param callback fun(entity: entity_t): string?
function esp.local_player.add_text(text_name, preview_value, callback) end;

engine = {};

---@param cmd string
engine.execute_client_cmd = function(cmd) end;

---@class surface_t
---@field name string	
---@field props number	
---@field flags number

---@class plane_t
---@field normal vec3_t	
---@field dist number	
---@field type number	
---@field signbits number

---@class trace_t
---@field start_pos vec3_t Start position
---@field end_pos vec3_t Final position
---@field plane plane_t Surface normal at impact.
---@field fraction number Percentage in the range [0.0, 1.0]. How far the trace went before hitting something. 1.0 - didn't hit anything
---@field contents number Contents on other side of surface hit
---@field disp_flags number Displacement flags for marking surfaces with data
---@field all_solid boolean Returns true if the plane is invalid
---@field start_solid boolean Returns true if the initial point was in a solid area
---@field surface surface_t Surface hit (impact surface).
---@field hitgroup number 0 - generic, non-zero is specific body part
---@field physics_bone number Physics bone that was hit by the trace
---@field world_surface_index number Index of the msurface2_t, if applicable
---@field entity entity_t Entity that was hit by the trace
---@field hitbox number Hitbox that was hit by the trace
---@field did_hit fun(): boolean Returns true if there was any kind of impact at all
---@field did_hit_world fun(): boolean Returns true if the entity points at the world entity
---@field did_hit_non_world fun(): boolean Returns true if the trace hit something and it wasn't the world
---@field is_visible fun(): boolean Returns true if the final position is visible

---@param from vec3_t
---@param to vec3_t
---@param skip? entity_t
---@param mask? number
---@param type? 0|1|2|3
---@return trace_t
engine.trace_line = function(from, to, skip, mask, type) end;

---@param from vec3_t
---@param to vec3_t
---@param mins vec3_t
---@param maxs vec3_t
---@param skip? entity_t
---@param mask? number
---@param type? 0|1|2|3
---@return trace_t
engine.trace_hull = function(from, to, mins, maxs, skip, mask, type) end;

---@param table_name string
---@param prop_name string
---@return number?
engine.get_netvar_offset = function(table_name, prop_name) end;

---@return angle_t?
engine.get_view_angles = function() end;

---@param angles angle_t
engine.set_view_angles = function(angles) end;

entitylist = {};

---@param idx_or_user_id number
---@param is_user_id? boolean
---@return entity_t?
entitylist.get = function(idx_or_user_id, is_user_id) end;

---@return entity_t?
entitylist.get_local_player = function() end;

---@param class_name_or_id string|number
---@param include_dormant? boolean
---@param callback fun(entity: entity_t)
---@overload fun(class_name_or_id: string|number, include_dormant: boolean): entity_t[]
entitylist.get_entities = function(class_name_or_id, include_dormant, callback) end;

---@class cvar_t
---@field get_name fun(self: cvar_t): string
---@field get_bool fun(self: cvar_t): boolean
---@field get_int fun(self: cvar_t): number
---@field get_float fun(self: cvar_t): number
---@field get_string fun(self: cvar_t): string
---@field set_bool fun(self: cvar_t, value: boolean)
---@field set_int fun(self: cvar_t, value: number)
---@field set_float fun(self: cvar_t, value: number)
---@field set_string fun(self: cvar_t, value: string)

---@type table<string, cvar_t>
cvars = {};

---@class __globals_t
---@field cur_time number Current server time in seconds
---@field real_time number Current local time in seconds
---@field frame_time number Time that was used to render a last game frame in seconds
---@field frame_count number Total rendered frames count
---@field absolute_frame_time number Time that was used to render a last game frame in seconds
---@field tick_count number Count of ticks that server has handled
---@field interval_per_tick number Duration of a tick in seconds
---@field max_clients number Maximum number of players allowed on the server
---@field choked_commands number Count of choked commands
---@field command_ack number Last command that server has been acknowledged of
---@field last_outgoing_command number Number of last command sequence number acknowledged by server
---@field delta_tick number Last valid received server tick
---@field is_connected boolean Is client connected to server or loading in game
---@field is_in_game boolean Is client loaded to server and in game
---@field camera_in_third_person boolean Is camera in third person
globals = {};

---@class game_event_t
---@field get_name fun(self: game_event_t): string
---@field get_bool fun(self: game_event_t, key_name: string, default_value?: boolean): boolean
---@field get_int fun(self: game_event_t, key_name: string, default_value?: number): number
---@field get_uint64 fun(self: game_event_t, key_name: string, default_value?: number): number
---@field get_float fun(self: game_event_t, key_name: string, default_value?: number): number
---@field get_string fun(self: game_event_t, key_name: string, default_value?: string): string
---@field get_wstring fun(self: game_event_t, key_name: string, default_value?: string): string
---@field set_bool fun(self: game_event_t, key_name: string, value: boolean)
---@field set_int fun(self: game_event_t, key_name: string, value: number)
---@field set_uint64 fun(self: game_event_t, key_name: string, value: number)
---@field set_float fun(self: game_event_t, key_name: string, value: number)
---@field set_string fun(self: game_event_t, key_name: string, value: string)
---@field set_wstring fun(self: game_event_t, key_name: string, value: string)

---@class user_cmd_t
---@field send_packet boolean Is packet will be sent to the server (fake lag)
---@field command_number number Current command number
---@field tick_count number Current tick count
---@field viewangles angle_t Crosshair angle
---@field forwardmove number Forward/backward speed
---@field sidemove number Left/right speed
---@field upmove number Up/down speed
---@field buttons number Buttons bit field
---@field random_seed number Random seed for shared random functions
---@field mousedx number Mouse X movement delta
---@field mousedy number Mouse Y movement delta

---@class view_setup_t
---@field fov number	
---@field view angle_t	
---@field camera vec3_t

---@alias __game_events "player_death"|"other_death"|"player_hurt"|"item_purchase"|"bomb_beginplant"|"bomb_abortplant"|"bomb_planted"|"bomb_defused"|"bomb_exploded"|"bomb_dropped"|"bomb_pickup"|"defuser_dropped"|"defuser_pickup"|"announce_phase_end"|"cs_intermission"|"bomb_begindefuse"|"bomb_abortdefuse"|"hostage_follows"|"hostage_hurt"|"hostage_killed"|"hostage_rescued"|"hostage_stops_following"|"hostage_rescued_all"|"hostage_call_for_help"|"vip_escaped"|"vip_killed"|"player_radio"|"bomb_beep"|"weapon_fire"|"weapon_fire_on_empty"|"grenade_thrown"|"weapon_outofammo"|"weapon_reload"|"weapon_zoom"|"silencer_detach"|"inspect_weapon"|"weapon_zoom_rifle"|"player_spawned"|"item_pickup"|"item_pickup_slerp"|"item_pickup_failed"|"item_remove"|"ammo_pickup"|"item_equip"|"enter_buyzone"|"exit_buyzone"|"buytime_ended"|"enter_bombzone"|"exit_bombzone"|"enter_rescue_zone"|"exit_rescue_zone"|"silencer_off"|"silencer_on"|"buymenu_open"|"buymenu_close"|"round_prestart"|"round_poststart"|"round_start"|"round_end"|"grenade_bounce"|"hegrenade_detonate"|"flashbang_detonate"|"smokegrenade_detonate"|"smokegrenade_expired"|"molotov_detonate"|"decoy_detonate"|"decoy_started"|"tagrenade_detonate"|"inferno_startburn"|"inferno_expire"|"inferno_extinguish"|"decoy_firing"|"bullet_impact"|"player_footstep"|"player_jump"|"player_blind"|"player_falldamage"|"door_moving"|"round_freeze_end"|"mb_input_lock_success"|"mb_input_lock_cancel"|"nav_blocked"|"nav_generate"|"player_stats_updated"|"achievement_info_loaded"|"spec_target_updated"|"spec_mode_updated"|"hltv_changed_mode"|"cs_game_disconnected"|"cs_win_panel_round"|"cs_win_panel_match"|"cs_match_end_restart"|"cs_pre_restart"|"show_freezepanel"|"hide_freezepanel"|"freezecam_started"|"player_avenged_teammate"|"achievement_earned"|"achievement_earned_local"|"item_found"|"items_gifted"|"repost_xbox_achievements"|"match_end_conditions"|"round_mvp"|"player_decal"|"teamplay_round_start"|"show_survival_respawn_status"|"client_disconnect"|"gg_player_levelup"|"ggtr_player_levelup"|"assassination_target_killed"|"ggprogressive_player_levelup"|"gg_killed_enemy"|"gg_final_weapon_achieved"|"gg_bonus_grenade_achieved"|"switch_team"|"gg_leader"|"gg_team_leader"|"gg_player_impending_upgrade"|"write_profile_data"|"trial_time_expired"|"update_matchmaking_stats"|"player_reset_vote"|"enable_restart_voting"|"sfuievent"|"start_vote"|"player_given_c4"|"player_become_ghost"|"gg_reset_round_start_sounds"|"tr_player_flashbanged"|"tr_mark_complete"|"tr_mark_best_time"|"tr_exit_hint_trigger"|"bot_takeover"|"tr_show_finish_msgbox"|"tr_show_exit_msgbox"|"reset_player_controls"|"jointeam_failed"|"teamchange_pending"|"material_default_complete"|"cs_prev_next_spectator"|"cs_handle_ime_event"|"nextlevel_changed"|"seasoncoin_levelup"|"tournament_reward"|"start_halftime"|"ammo_refill"|"parachute_pickup"|"parachute_deploy"|"dronegun_attack"|"drone_dispatched"|"loot_crate_visible"|"loot_crate_opened"|"open_crate_instr"|"smoke_beacon_paradrop"|"survival_paradrop_spawn"|"survival_paradrop_break"|"drone_cargo_detached"|"drone_above_roof"|"choppers_incoming_warning"|"firstbombs_incoming_warning"|"dz_item_interaction"|"snowball_hit_player_face"|"survival_teammate_respawn"|"survival_no_respawns_warning"|"survival_no_respawns_final"|"player_ping"|"player_ping_stop"|"guardian_wave_restart"|"team_info"|"team_score"|"teamplay_broadcast_audio"|"player_team"|"player_class"|"player_chat"|"player_score"|"player_spawn"|"player_shoot"|"player_use"|"player_changename"|"player_hintmessage"|"base_player_teleported"|"game_init"|"game_newmap"|"game_start"|"game_end"|"game_message"|"break_breakable"|"break_prop"|"entity_killed"|"bonus_updated"|"achievement_event"|"achievement_increment"|"physgun_pickup"|"flare_ignite_npc"|"helicopter_grenade_punt_miss"|"user_data_downloaded"|"ragdoll_dissolved"|"hltv_changed_target"|"vote_ended"|"vote_started"|"vote_changed"|"vote_passed"|"vote_failed"|"vote_cast"|"vote_options"|"replay_saved"|"entered_performance_mode"|"browse_replays"|"replay_youtube_stats"|"inventory_updated"|"cart_updated"|"store_pricesheet_updated"|"gc_connected"|"item_schema_initialized"
---@type
---| fun(name: "create_move", callback: fun(cmd: user_cmd_t))
---| fun(name: "override_view", callback: fun(view_setup: view_setup_t))
---| fun(name: __game_events, callback: fun(event: game_event_t))
---| fun(name: "unload", callback: fun())
---| fun(name: "paint", callback: fun())
register_callback = function(name, callback) end;

---@param text string
---@param color? color_t
print = function(text, color) end;

---@param module string
---@param pattern string
---@param offset? number
---@return ffi.cdata*
find_pattern = function(module, pattern, offset) end;
