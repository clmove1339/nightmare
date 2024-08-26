local ui = {}; do
    ---@type c_tab[]
    local tabs = {};
    local base_path = 'Movement/Anti aim';
    local selector = menu.add_combo_box('Select tab', base_path, {});
    ---@type function[]
    local depend_list = {};
    local hash = {};

    local function get_hashed_path(path)
        if not hash[path] then
            hash[#hash + 1] = path;
            hash[path] = #hash;
        end;
        return hash[path];
    end;

    ---@param element menu_item
    ---@param depends table
    local function depend(element, depends)
        depend_list[#depend_list + 1] = function()
            local visible = true;

            for _, dependant in ipairs(depends) do
                if (type(dependant) == 'table') then
                    if dependant[1].__type.name == 'base_multi_combo_box_t' then
                        visible = dependant[1]:get(dependant[2]);
                    else
                        visible = dependant[1]:get() == dependant[2];
                    end;
                else
                    visible = dependant;
                end;

                if not visible then
                    break;
                end;
            end;

            element:set_visible(element:is_visible() and visible);
        end;
    end;

    local override_list = {};

    local function override(self, value, index)
        local element = self;
        local name = element;

        if override_list[name] == nil then
            override_list[name] = {
                element = element,
                old_value = nil,
                overrided = false,
            };
        end;

        local data = override_list[name];
        local overrided = data.overrided;

        if not menu.is_visible() and value ~= nil then
            if not overrided then
                data.old_value = self:get(index);

                data.overrided = true;
            end;

            element:set(unpack({ value, index }));
        else
            if overrided then
                local value = data.old_value;
                element:set(unpack({ value, index }));
                data.overrided = false;
            end;
        end;

        return data;
    end;

    ---@param element any
    ---@param i? any
    ---@param upvalue? boolean
    ---@return boolean
    local function handle_value(element, i, upvalue)
        if not element and upvalue then
            return upvalue;
        end;

        local type = typeof(element);
        local is_i_number = typeof(tonumber(i)) == 'number';
        local i = is_i_number and tonumber(i) or i;

        if type == 'base_check_box_t' then
            return element:get();
        elseif type == 'base_combo_box_t' then
            print(i);
            if is_i_number then
                return element:get() == i - 1;
            else
                return element:get() ~= 0;
            end;
        elseif type == 'base_multi_combo_box_t' and is_i_number then
            return element:get(i);
        elseif type == 'base_slider_int_t' and is_i_number then
            return element:get() == i;
        elseif type == 'base_slider_float_t' and is_i_number then
            return math.abs(element:get() - i) < 0.01;
        elseif type == 'base_key_bind_t' then
            return element:is_active();
        elseif type == 'base_color_picker_t' then
            return element:get() == i;
        end;

        return false;
    end;

    ---@param table table<string|number, menu_item[]|menu_item>
    ---@param upvalue? boolean
    ---@param master? menu_item
    local function recursive_visible(table, upvalue, master)
        if master then
            recursive_visible({ master = master, table }, upvalue);
            return;
        end;

        local master = table.master or master;
        local upvalue = upvalue == nil and true or upvalue;

        for id, dependant in pairs(table) do
            local is_master = id == 'master';
            local is_visible = handle_value(master, id, upvalue);
            local type = typeof(dependant);

            if type == 'table' then
                recursive_visible(dependant, upvalue and is_visible);
            elseif type:find('base_') then
                dependant:set_visible((is_master and upvalue) or (is_visible and upvalue) or false);
            end;
        end;
    end;

    ---@param element menu_item
    ---@param connections table
    ---@param is_active boolean
    local function connect(element, connections, is_active)
        depend_list[#depend_list + 1] = function()
            recursive_visible(connections, is_active, element);
            print('\n');
        end;
    end;

    local menu_items_list = {
        check_box_t,
        combo_box_t,
        multi_combo_box_t,
        slider_float_t,
        slider_int_t,
        key_bind_t,
        button_t,
        color_picker_t,
    };

    for _, item in pairs(menu_items_list) do
        item.depend = depend;
        item.override = override;
        item.connect = connect;
    end;

    ---@diagnostic disable-next-line: circle-doc-class
    ---@class menu_item: menu_item
    ---@field depend fun(self: menu_item, depends: table<table|boolean>): nil
    ---@field connect fun(self: menu_item, connections: table<menu_item|menu_item[]>): nil Adds a function to the dependency list that manages the visibility of connected elements based on the state of `element`.

    ---@class c_tab : menu_item
    ---@field name string
    ---@field elements table
    ---@field location string
    ---@field switch fun(self: c_tab, label: string, default_value?: boolean, is_group?: true, location?: string): c_tab, check_box_t
    ---@field switch fun(self: c_tab, label: string, default_value?: boolean, is_group?: false, location?: string): check_box_t, nil
    ---@field button fun(self: c_tab, label: string, fn: function, location?: string): button_t
    ---@field color fun(self: c_tab, label: string, default_value?: color_t, show_label?: boolean, show_alpha?: boolean, location?: string): color_picker_t
    ---@field combo fun(self: c_tab, label: string, items: string[], default_value?: number, location?: string): combo_box_t
    ---@field keybind fun(self: c_tab, label: string, show_label?: boolean, key?: number, type?: number, display_in_list?: boolean, location?: string): key_bind_t
    ---@field multicombo fun(self: c_tab, label: string, items: string[], default_value?: number[], location?: string): multi_combo_box_t
    ---@field slider_int fun(self: c_tab, label: string, min: number, max: number, default_value?: number, location?: string): slider_int_t
    ---@field slider_float fun(self: c_tab, label: string, min: number, max: number, default_value?: number, location?: string): slider_float_t
    local c_tab = {}; do
        ---@private
        function c_tab:new(name, location)
            local instance = setmetatable({
                name = name,
                location = location or base_path,
                elements = {}
            }, { __index = c_tab });

            return instance;
        end;

        function c_tab:switch(label, default_value, is_group, location)
            local location = location or self.location;
            local path = string.format('%s/%s', location, label);
            local hashed_path = get_hashed_path(path);

            local path_label = string.format('%s##%d', label, hashed_path);
            local context = is_group and string.format('%s %s group', location, path_label) or nil;
            local shown_label = string.format('%s%s##%d', label, (is_group and ' [  ]' or ''), hashed_path);

            local element = menu.add_check_box(shown_label, location, default_value, context);
            self.elements[#self.elements + 1] = element;

            if is_group then
                return c_tab:new(path_label, context), element;
            end;

            return element;
        end;

        function c_tab:button(label, fn)
            local location = location or self.location;
            local path = string.format('%s/%s', location, label);
            local hashed_path = get_hashed_path(path);

            label = string.format('%s##%d', label, hashed_path);
            local element = menu.add_button(label, location, fn or function() end);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:color(label, default_value, show_label, show_alpha, location)
            local location = location or self.location;
            local path = string.format('%s/%s', location, label);
            local hashed_path = get_hashed_path(path);

            label = string.format('%s##%d', label, hashed_path);
            local element = menu.add_color_picker(label, location, show_label, show_alpha, default_value);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:combo(label, items, default_value, location)
            local location = location or self.location;
            local path = string.format('%s/%s', location, label);
            local hashed_path = get_hashed_path(path);

            label = string.format('%s##%d', label, hashed_path);
            local element = menu.add_combo_box(label, location, items, default_value);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:keybind(label, show_label, key, type, display_in_list, location)
            local location = location or self.location;
            local path = string.format('%s/%s', location, label);
            local hashed_path = get_hashed_path(path);

            label = string.format('%s##%d', label, hashed_path);
            local element = menu.add_key_bind(label, location, show_label, key, type, display_in_list);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:multicombo(label, items, default_value, location)
            local location = location or self.location;
            local path = string.format('%s/%s', location, label);
            local hashed_path = get_hashed_path(path);

            label = string.format('%s##%d', label, hashed_path);
            local element = menu.add_multi_combo_box(label, location, items, default_value or {});
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:slider_int(label, min, max, default_value, location)
            local location = location or self.location;
            local path = string.format('%s/%s', location, label);
            local hashed_path = get_hashed_path(path);

            label = string.format('%s##%d', label, hashed_path);
            local element = menu.add_slider_int(label, location, min, max, default_value);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:slider_float(label, min, max, default_value, location)
            local location = location or self.location;
            local path = string.format('%s/%s', location, label);
            local hashed_path = get_hashed_path(path);

            label = string.format('%s##%d', label, hashed_path);
            local element = menu.add_slider_float(label, location, min, max, default_value);
            self.elements[#self.elements + 1] = element;

            return element;
        end;
    end;

    ---@param name string
    ---@return c_tab
    function ui.create(name)
        local tab = c_tab:new(name);

        tabs[#tabs + 1] = tab;

        local tab_names = {};

        for _, tab in ipairs(tabs) do
            tab_names[#tab_names + 1] = tab.name;
        end;

        selector:set_items(tab_names);

        return tab;
    end;

    function ui.hide(value)
        for _, element in pairs(nixware['Movement']['Anti aim']) do
            element:set_visible(not value);
        end;
        nixware['Movement']['Fakelag'].limit:set_visible(not value);
    end;

    function ui.delete(name)
        for i, tab in ipairs(tabs) do
            if tab.name == name then
                table.remove(tabs, i);
                break;
            end;
        end;
    end;

    function ui.handle()
        local selected = selector:get();
        for i, tab in ipairs(tabs) do
            local is_tab_visible = selected + 1 == i;
            for _, element in pairs(tab.elements) do
                element:set_visible(is_tab_visible);
            end;
        end;

        for _, fn in ipairs(depend_list) do
            fn();
        end;
    end;

    ui.hide(true);

    register_callback('paint', function()
        xpcall(ui.handle, print);
    end);

    register_callback('unload', function()
        ui.hide(false);
    end);
end;

return ui;
