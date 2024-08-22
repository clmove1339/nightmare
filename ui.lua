local ui = {}; do
    ---@type c_tab[]
    local tabs = {};
    local base_path = 'Movement/Anti aim';
    local selector = menu.add_combo_box('Select tab', base_path, {});
    ---@type function[]
    local depend_list = {};

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

            element:set_visible(visible);
        end;
    end;

    check_box_t.depend = depend;
    combo_box_t.depend = depend;
    multi_combo_box_t.depend = depend;
    slider_float_t.depend = depend;
    slider_int_t.depend = depend;
    key_bind_t.depend = depend;
    button_t.depend = depend;
    color_picker_t.depend = depend;

    ---@class c_tab
    ---@field name string
    ---@field elements table
    ---@field location string
    ---@field switch fun(self: c_tab, label: string, default_value?: boolean, is_group: true): c_tab, check_box_t
    ---@field switch fun(self: c_tab, label: string, default_value?: boolean, is_group: false): check_box_t
    ---@field switch fun(self: c_tab, label: string, default_value?: boolean, is_group: nil): check_box_t
    ---@field button fun(self: c_tab, label: string, fn: function): button_t
    ---@field color fun(self: c_tab, label: string, default_value?: color_t, show_label?: boolean, show_alpha?: boolean): color_picker_t
    ---@field combo fun(self: c_tab, label: string, items: string[], default_value?: number): combo_box_t
    ---@field keybind fun(self: c_tab, label: string, show_label?: boolean, key?: number, type?: number, display_in_list?: boolean): key_bind_t
    ---@field multicombo fun(self: c_tab, label: string, items: string[], default_value?: number[]): multi_combo_box_t
    ---@field slider_int fun(self: c_tab, label: string, min: number, max: number, default_value?: number): slider_int_t
    ---@field slider_float fun(self: c_tab, label: string, min: number, max: number, default_value?: number): slider_float_t
    local c_tab = {}; do
        ---@private
        function c_tab:new(name, location)
            local instance = {
                name = name,
                location = location or base_path,
                elements = {}
            };

            setmetatable(instance, { __index = c_tab });

            return instance;
        end;

        function c_tab:switch(label, default_value, is_group)
            local context = is_group and string.format('%s %s group', self.location, label) or nil;
            local element = menu.add_check_box(label .. (is_group and ' [  ]' or ''), self.location, default_value, context);
            self.elements[#self.elements + 1] = element;

            if is_group then
                return c_tab:new(label, context), element;
            end;

            return element;
        end;

        function c_tab:button(label, fn)
            local element = menu.add_button(label, self.location, fn or function() end);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:color(label, default_value, show_label, show_alpha)
            local element = menu.add_color_picker(label, self.location, show_label, show_alpha, default_value);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:combo(label, items, default_value)
            local element = menu.add_combo_box(label, self.location, items, default_value);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:keybind(label, show_label, key, type, display_in_list)
            local element = menu.add_key_bind(label, self.location, show_label, key, type, display_in_list);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:multicombo(label, items, default_value)
            local element = menu.add_multi_combo_box(label, self.location, items, default_value or {});
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:slider_int(label, min, max, default_value)
            local element = menu.add_slider_int(label, self.location, min, max, default_value);
            self.elements[#self.elements + 1] = element;

            return element;
        end;

        function c_tab:slider_float(label, min, max, default_value)
            local element = menu.add_slider_float(label, self.location, min, max, default_value);
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
        --[[
            for _, element in pairs(nixware['Movement']['Movement']) do
                element:set_visible(not value);
            end;

            nixware['Movement']['Fakelag'].limit:set_visible(not value);
        --]]
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
