do
    local import = require;

    ---@param modname string
    ---@return any
    require = function(modname)
        local success, module = pcall(import, modname);

        if not success then
            module = import(string.format('nightmare.%s', modname));
        end;

        return module;
    end;
end;

require 'nixware';
require 'global';

local ui = require 'ui';
local memory = require 'memory';
local utils = require 'utils';
local engine_client = require 'engine_client';
local vmt = require 'vmt';

local aimbot = {}; do
    ---@private
    local handle = ui.create('Aimbot');

    local e = handle:switch('ENABLE CUSTOM_RESOZOLVER');

    handle:combo('Resolver Type', {
        'Off',
        'Default',
        'Extended'
    });
end;

local antiaim = {}; do
    ---@private
    local handle = ui.create('Anti-aimbot');
    local enable = handle:switch('Enabled', false);
    local sub_handle = handle:combo('Anti-aimbot part:', { 'General', 'Settings' });

    sub_handle:depend({ { enable, true } });

    antiaim.general = {}; do
        local features = handle:multicombo('Features', { 'Anti-backstab', 'Manual anti-aim' });

        local manual = {
            left = handle:keybind('Manual left'),
            right = handle:keybind('Manual right'),
            reset = handle:keybind('Manual reset'),
            static = handle:switch('Use static on manual'),
        };

        features:depend({ { enable, true }, { sub_handle, 0 } });
        manual.left:depend({ { enable, true }, { sub_handle, 0 }, { features, 1 } });
        manual.right:depend({ { enable, true }, { sub_handle, 0 }, { features, 1 } });
        manual.reset:depend({ { enable, true }, { sub_handle, 0 }, { features, 1 } });
        manual.static:depend({ { enable, true }, { sub_handle, 0 }, { features, 1 } });
    end;

    local states = { 'Default', 'Standing', 'Running', 'Walking', 'Crouching', 'Sneaking', 'In Air', 'In Air & Crouching' };
    local netvars = {
        m_fFlags = engine.get_netvar_offset('DT_BasePlayer', 'm_fFlags'),
        m_flDuckAmount = engine.get_netvar_offset('DT_BasePlayer', 'm_flDuckAmount'),
    }; -- мне абсолютно поебать что оно возможно не там где надо находится

    function antiaim:get_statement(cmd)
        local me = entitylist.get_local_player();

        if not me then
            return states[1];
        end;

        local flags = ffi.cast('int*', me[netvars.m_fFlags])[0];
        local duck_amount = ffi.cast('int*', me[netvars.m_flDuckAmount])[0];
        local velocity = math.floor(math.abs(cmd.forwardmove) + math.abs(cmd.sidemove));

        local is_fake_duck = menu.find_check_box('Fake duck', 'Movement/Movement'):get() and menu.find_key_bind('Fake duck', 'Movement/Movement'):is_active();

        local in_crouch = duck_amount > 0 or is_fake_duck;
        local in_air = bit.band(cmd.buttons, bit.lshift(1, 1)) == bit.lshift(1, 1) or bit.band(flags, bit.lshift(1, 0)) == 0;
        local in_speed = bit.band(cmd.buttons, bit.lshift(1, 17)) == bit.lshift(1, 17);

        if in_air then
            return states[in_crouch and 8 or 7];
        end;

        if in_crouch then
            return states[velocity > 1.1 * 3.3 and 6 or 5];
        end;

        if velocity > 1.1 * 3.3 then
            return states[in_speed and 4 or 3];
        end;

        return states[2];
    end;

    antiaim.builder = {}; do
        local information = {};
        local state_selector = handle:combo('State', states, 0);

        state_selector:depend({ { enable, true }, { sub_handle, 1 } });

        local function setup_state(state, index)
            local state_info = {
                override = handle:switch('Override ' .. state, state == 'Default'),
                pitch = handle:combo('Pitch##' .. state, { 'None', 'Down', 'Fake down', 'Fake up' }, 1),
                base_yaw = handle:combo('Base yaw##' .. state, { 'Local view', 'Static', 'At targets' }, 2),
                yaw_offset = handle:slider_int('Yaw offset##' .. state, -180, 180, 180),
                yaw_modifier = handle:combo('Yaw modifier##' .. state, { 'None', 'Center', 'Offset', 'Random', '3-Way', '5-Way' }, 0),
                yaw_modifier_offset = handle:slider_int('Yaw modifier offset##' .. state, -180, 180, 0),
                yaw_desync = handle:combo('Yaw desync##' .. state, { 'None', 'Static', 'Jitter', 'Random Jitter' }),
                yaw_desync_length = handle:slider_int('Yaw desync length##' .. state, 0, 60, 0)
            };

            for element_name, element in pairs(state_info) do
                local is_default_state = state == 'Default';
                local is_override_checkbox = element_name == 'override';

                element:depend({ { enable, true }, { state_selector, index - 1 }, { sub_handle, 1 }, not (is_default_state and is_override_checkbox), (is_default_state or is_override_checkbox) and true or { state_info.override, true } });
            end;

            information[state] = state_info;
        end;

        for i, state in ipairs(states) do
            setup_state(state, i);
        end;

        local base_path = 'Movement/Anti aim';

        local elements = {
            pitch = menu.find_combo_box('Pitch', base_path),
            base_yaw = menu.find_combo_box('Base yaw', base_path),
            yaw_offset = menu.find_slider_int('Yaw offset', base_path),
            yaw_modifier = menu.find_combo_box('Yaw modifier', base_path),
            yaw_modifier_offset = menu.find_slider_int('Yaw modifier offset', base_path),
            yaw_desync = menu.find_combo_box('Yaw desync', base_path),
            yaw_desync_length = menu.find_slider_int('Yaw desync length', base_path),
        };

        local native_enabled = nixware['Movement']['Anti aim'].enabled:get();

        local function setup(cmd)
            nixware['Movement']['Anti aim'].enabled:set(enable:get());

            local statement = information[antiaim:get_statement(cmd)].override:get() and antiaim:get_statement(cmd) or 'Default';
            local settings = information[statement];

            for name, element in pairs(settings) do
                if name == 'override' then
                    goto continue;
                end;

                elements[name]:set(element:get());

                ::continue::
            end;
        end;

        register_callback('create_move', function(cmd)
            xpcall(setup, print, cmd);
        end);

        register_callback('unload', function()
            nixware['Movement']['Anti aim'].enabled:set(native_enabled);
        end);
    end;
end;

local visualization = {}; do
    ---@private
    local handle = ui.create('Visualization');

    -- и тут мне тоже абсолютно поебать, сами подравите как надо ( либо я как проснусь )
    local old_value = cvars.cam_idealdist:get_int();
    local camera_distance = handle:slider_int('3rd person distance', 30, 180, old_value);

    register_callback('paint', function()
        if camera_distance:get() ~= old_value then
            cvars.cam_idealdist:set_int(camera_distance:get());
        end;
    end);
end;

local skinchanger = {}; do
    local m_lifeState = engine.get_netvar_offset('DT_BasePlayer', 'm_lifeState');
    local m_hActiveWeapon = engine.get_netvar_offset('DT_BaseCombatCharacter', 'm_hActiveWeapon');

    local IClientEntityList = memory:interface('client', 'VClientEntityList003', {
        GetClientEntity = { 3, 'uintptr_t(__thiscall*)(void*, int)' },
        GetClientEntityFromHandle = { 4, 'uintptr_t(__thiscall*)(void*, uintptr_t)' }
    });

    function entity_t:is_alive()
        return ffi.cast('char*', self[m_lifeState])[0] == 0;
    end;

    local main = ui.create('Skinchanger');

    --#region structs
    ffi.cdef [[
    struct SOID {
        unsigned long long id;
        unsigned int type;
        unsigned int padding;
    };

    struct econ_item {
        unsigned char pad_x0[8]; //0x0
        unsigned long long item_id; //0x8
        unsigned long long original_id; //0x10
        uint32_t* custom_data_optimized_object; //0x18
        unsigned int account_id; //0x1C
        unsigned int inventory; //0x20
        unsigned short weapon_idx; //0x24

        uint16_t origin : 5;
        uint16_t quality : 4;
        uint16_t level : 2;
        uint16_t rarity : 4;
        uint16_t dirtybitInUse : 1;

        int16_t itemSet;
        int soUpdateFrame;
        uint8_t flags;
    };
]];

    local string_t = [[struct {
    char* buffer;
    int capacity;
    int grow_size;
    int length;
}]];

    local alternate_icon_data = [[struct {
    ]] .. string_t .. [[ simpleName;
    ]] .. string_t .. [[ largeSimpleName;
    ]] .. string_t .. [[ iconURLSmall;
    ]] .. string_t .. [[ iconURLLarge;
    char pad0[28];
}]];

    local econ_item_quality_definition = [[struct {
    int value;
    const char* name;
    unsigned weight;
    bool explicitMatchesOnly;
    bool canSupportSet;
    const char* hexColor;
}]];

    local paint_kit_t = [[struct {
    int nID;

    ]] .. string_t .. [[ name;
    ]] .. string_t .. [[ description;
    ]] .. string_t .. [[ tag;
    ]] .. string_t .. [[ same_name_family_aggregate;
    ]] .. string_t .. [[ pattern;
    ]] .. string_t .. [[ normal;
    ]] .. string_t .. [[ logoMaterial;
    bool baseDiffuseOverride;
    int rarity;
    char pad[40];
    float wearRemapMin;
    float wearRemapMax;
}]];

    local sticker_kit_t = [[struct {
    int id;
    int rarity;
    ]] .. string_t .. [[ name;
    ]] .. string_t .. [[ description;
    ]] .. string_t .. [[ itemName;
    char pad0[]] .. ffi.sizeof(ffi.typeof(string_t)) * 2 .. [[];
    ]] .. string_t .. [[ inventoryImage;
}]];

    local econ_music_definition = [[struct {
    int id;
    const char* name;
    const char* nameLocalized;
    char pad0[]] .. ffi.sizeof(ffi.typeof('const char*')) * 2 .. [[];
    const char* inventoryImage;
}]];

    local create_map_t = function(key_type, value_type)
        return ffi.typeof([[struct {
    void* lessFunc;
    struct {
        struct {
            int left;
            int right;
            int parent;
            int type;
            $ key;
            $ value;
        }* memory;
        int allocationCount;
        int growSize;
    } memory;
    int root;
    int num_elements;
    int firstFree;
    int lastAlloc;
    struct {
        int left;
        int right;
        int parent;
        int type;
        $ key;
        $ value;
    }* elements;
}
]], ffi.typeof(key_type), ffi.typeof(value_type), ffi.typeof(key_type), ffi.typeof(value_type));
    end;

    item_schema_t = ffi.typeof([[struct {
    char pad0[0x88];
    $ qualities;
    char pad1[0x48];
    $ items_sorted;
    char pad2[0x60];
    $ revolving_loot_lists;
    char pad3[0x80];
    $ alternate_icons;
    char pad4[0x48];
    $ paint_kits;
    $ sticker_kits;
    char pad5[0x11C];
    $ music_kits;
}*
]],
        create_map_t('int', econ_item_quality_definition),
        create_map_t('int', 'uint32_t*'),
        create_map_t('int', 'const char*'),
        create_map_t('uint64_t', alternate_icon_data .. '*'),
        create_map_t('int', paint_kit_t .. '*'),
        create_map_t('int', sticker_kit_t .. '*'),
        create_map_t('int', econ_music_definition .. '*')
    );
    --#endregion

    local function vtable_thunk(index, ...)
        local ctype = ffi.typeof(...);

        return function(instance, ...)
            assert(instance ~= nil, 'invalid instance');

            local vtable = ffi.cast('void***', instance);
            local vfunc = ffi.cast(ctype, vtable[0][index]);

            return vfunc(instance, ...);
        end;
    end;

    local get_item_schema_addr = find_pattern('client.dll', 'A1 ? ? ? ? 85 C0 75 53') or error('cant find get_item_scham()');
    local get_item_schema_fn = ffi.cast('uint32_t(__stdcall*)()', get_item_schema_addr);

    local follow_call = function(ptr)
        local insn = ffi.cast('uint8_t*', ptr);

        if insn[0] == 0xE8 then
            local offset = ffi.cast('int32_t*', insn + 1)[0];

            return insn + offset + 5;
        elseif insn[0] == 0xFF and insn[1] == 0x15 then
            local call_addr = ffi.cast('uint32_t**', ffi.cast('const char*', ptr) + 2);

            return call_addr[0][0];
        elseif insn[0] == 0xB0 then
            return ffi.cast('uint32_t', ptr + 4 + read('uint32_t', ptr));
        else
            error(string.format('unknown instruction to follow: %02X!', insn[0]));
        end;
    end;

    local get_paint_kit_definition_addr = find_pattern('client.dll', 'E8 ? ? ? ? 8B F0 8B 4E 7C') or error('cant find get_paint_kit_definition');
    local get_paint_kit_definition_fn = ffi.cast('void*(__thiscall*)(void*, int)', follow_call(get_paint_kit_definition_addr));

    local item_schema_c = {}; do
        function item_schema_c.create(ptr)
            return setmetatable({
                ptr = ptr,
                get_item_definition_interface_vf = vtable_thunk(4, 'void*(__thiscall*)(void* item_schema, short id)'),
                get_attribute_definition_interface_vf = vtable_thunk(27, 'void*(__thiscall*)(void* item_schema, int index)'),
            }, {
                __index = item_schema_c,
                __metatable = 'item_schema'
            });
        end;

        function item_schema_c:get_item_definition_interface(id)
            return econ_item_definition_c.create(self.get_item_definition_interface_vf(self.ptr, id));
        end;

        function item_schema_c:get_attribute_definition_interface(index)
            return ffi.cast('void*', self.get_attribute_definition_interface_vf(self.ptr, index));
        end;

        function item_schema_c:get_paint_kit(index)
            local paint_kit_addr = get_paint_kit_definition_fn(self.ptr, index);
            if paint_kit_addr == nil then return; end;

            return ffi.cast(ffi.typeof(paint_kit_t .. '*'), paint_kit_addr);
        end;
    end;

    local schema = item_schema_c.create(ffi.cast(item_schema_t, get_item_schema_fn() + 4));

    local IBaseFileSystem = memory:interface('filesystem_stdio.dll', 'VBaseFileSystem011', {
        Open = { 2, 'void*(__thiscall*)(void*, const char*, const char*, const char*)' },
        Close = { 3, 'void(__thiscall*)(void*, void*)' }
    });

    local function is_file_valid(path)
        local handle = IBaseFileSystem:Open(path, 'r', 'GAME');
        if ffi.cast('uint32_t', handle) ~= 0 then
            IBaseFileSystem:Close(handle);
            return true;
        end;
        return false;
    end;

    local localize; do
        local ILocalize = memory:interface('localize.dll', 'Localize_001', {
            Find = { 13, 'wchar_t*(__thiscall*)(void*, const char*)' },
            ConvertANSIToUnicode = { 15, 'int(__thiscall*)(void*, const char*, wchar_t*, int)' },
            ConvertUnicodeToANSI = { 16, 'int(__thiscall*)(void*, wchar_t*, char*, int)' },
        });

        function localize(tag)
            local wchar = ILocalize:Find(tag);

            if (wchar == nil) then
                return;
            end;

            local buffer_size = 1024;
            local buffer = ffi.new('char[?]', buffer_size);

            ILocalize:ConvertUnicodeToANSI(wchar, buffer, buffer_size);
            return ffi.string(buffer);
        end;
    end;

    local skin_names = {};
    local skin_ids = {};

    local function create_skin_list(weapon_name)
        for i = 1, 11000 do
            if i == 3000 then
                i = 10000;
            end;

            local paint_kit = schema:get_paint_kit(i);

            if paint_kit ~= nil then
                ---@diagnostic disable: undefined-field
                local tag = localize(ffi.string(paint_kit.tag.buffer, paint_kit.tag.length - 1));
                local name = ffi.string(paint_kit.name.buffer, paint_kit.name.length - 1);
                ---@diagnostic enable

                if (tag ~= nil) then
                    local weapon_name = weapon_name;
                    local item_image = string.format('resource/flash/econ/default_generated/%s_%s_light_large.png', weapon_name, name);

                    if (is_file_valid(item_image)) then
                        skin_names[#skin_names + 1] = tag;
                        skin_ids[tag] = i;
                    end;
                end;
            end;
        end;
    end;


    create_skin_list('weapon_ssg08');
    local skin_selector = main:combo('skin', skin_names);

    register_callback('paint', function()
        print(skin_id);
    end);


    local gui = {
        wear = main:slider_float('Wear', 0.001, 1.0, 0.001),
        seed = main:slider_int('Seed', 1, 1000, 1)
    };

    local m_iItemIDHigh = engine.get_netvar_offset('DT_EconEntity', 'm_iItemIDHigh');
    local m_nFallbackPaintKit = engine.get_netvar_offset('DT_EconEntity', 'm_nFallbackPaintKit');
    local m_flFallbackWear = engine.get_netvar_offset('DT_EconEntity', 'm_flFallbackWear');
    local m_nFallbackSeed = engine.get_netvar_offset('DT_EconEntity', 'm_nFallbackSeed');

    local old_kit = -1;

    local m_nDeltaTick = ffi.cast('int*', ffi.cast('uintptr_t', ffi.cast('uintptr_t***', (ffi.cast('uintptr_t**', memory:create_interface('engine.dll', 'VEngineClient014'))[0][12] + 16))[0][0]) + 0x0174);

    local IBaseClientDLL = vmt:new(memory:create_interface('client.dll', 'VClient018')); do
        local FrameStages = {
            FRAME_UNDEFINED = -1,
            FRAME_START = 0,
            FRAME_NET_UPDATE_START = 1,
            FRAME_NET_UPDATE_POSTDATAUPDATE_START = 2,
            FRAME_NET_UPDATE_POSTDATAUPDATE_END = 3,
            FRAME_NET_UPDATE_END = 4,
            FRAME_RENDER_START = 5,
            FRAME_RENDER_END = 6
        };

        IBaseClientDLL:attach(37, 'void(__stdcall*)(int stage)', function(stage)
            xpcall(function()
                if (stage ~= FrameStages.FRAME_NET_UPDATE_POSTDATAUPDATE_START) then
                    return;
                end;

                local me = entitylist.get(engine_client:get_local_player());

                if (me == nil or not me:is_alive()) then
                    return;
                end;

                local weapon_handle = ffi.cast('int*', me[m_hActiveWeapon]);

                if (weapon_handle == nil) then
                    return;
                end;

                local weapon = IClientEntityList:GetClientEntityFromHandle(weapon_handle[0]);

                if (weapon == nil) then
                    return;
                end;

                local item_id_high = ffi.cast('int*', weapon + m_iItemIDHigh);
                local fallback_paint_kit = ffi.cast('int*', weapon + m_nFallbackPaintKit);
                local fallback_wear = ffi.cast('float*', weapon + m_flFallbackWear);
                local fallback_seed = ffi.cast('int*', weapon + m_nFallbackSeed);

                local selected_skin = skin_selector:get();
                local skin_name = skin_names[selected_skin + 1];
                local skin_id = skin_ids[skin_name];

                local paint = skin_id;
                local wear = gui.wear:get();
                local seed = gui.seed:get();

                item_id_high[0] = -1;
                fallback_paint_kit[0] = paint;
                fallback_wear[0] = wear;
                fallback_seed[0] = seed;

                if (old_kit ~= paint) then
                    old_kit = paint;

                    m_nDeltaTick[0] = -1;
                end;
            end, print);

            IBaseClientDLL:get_original(37)(stage);
        end);
    end;
end;
