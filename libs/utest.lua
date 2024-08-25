require('libs.global');

local test = {}; do
    ---@type table<string, table<string, function>>
    list = {};
    workspace = nil;

    test.set_workspace = function(name)
        workspace = name;
    end;

    ---@param name string
    ---@param fn function
    test.new = function(name, fn)
        if not workspace then
            return;
        end;

        if not list[workspace] then
            list[workspace] = {};
        end;

        list[workspace][name] = fn;
    end;

    ---@param workspace string
    test.done = function(workspace)
        if not workspace then
            return;
        end;

        local result = { total = 0, passed = 0, time = 0 };

        for name, fn in pairs(list[workspace]) do
            local start_time = os.clock();
            local status, msg = pcall(fn);
            local end_time = os.clock();
            local delta = (end_time - start_time) * 1000;
            result.total = result.total + 1;
            result.time = result.time + delta;

            if status == true then
                printf('%s test was passed in %.1f ms', name, delta);
                result.passed = result.passed + 1;
            else
                printf('%s test was failed in %.1f ms', name, delta);
                printf('reason: %s\n', msg);
            end;
        end;

        return result;
    end;

    ---@param workspace? string
    test.main = function(workspace)
        engine.execute_client_cmd('clear');

        if workspace then
            local result = test.done(workspace);
            if not result then
                return;
            end;

            printf('%s out of %s tests of the "%s" workspace were successful ( total execution time: %.2f )\n', result.passed, result.total, workspace, result.time);
        else
            for workspace, _ in pairs(list) do
                local result = test.done(workspace);
                if not result then
                    goto continue;
                end;

                printf('%s out of %s tests of the "%s" workspace were successful ( total execution time: %.2f )\n', result.passed, result.total, workspace, result.time);
                ::continue::
            end;
        end;
    end;
end;

test.set_workspace('ui');

test.new('ui.create', function()
    local ui = require('libs.ui');
    local A = ui.create('A');

    assert(
        type(A.button) == 'function' and
        type(A.color) == 'function' and
        type(A.combo) == 'function' and
        type(A.elements) == 'table' and
        type(A.keybind) == 'function' and
        type(A.location) == 'string' and
        type(A.multicombo) == 'function' and
        type(A.name) == 'string' and
        type(A.slider_float) == 'function' and
        type(A.slider_int) == 'function' and
        type(A.switch) == 'function'
    );

    local class, switch = A:switch('Switch group #1', true, true);

    assert(
        type(A.elements) == 'table' and
        type(A.location) == 'string' and
        type(A.name) == 'string' and
        type(A:button('Button #1', function() end)) == 'userdata' and
        type(A:color('Color picker #1', color_t.new(0, 0, 0, 0), true, true)) == 'userdata' and
        type(A:combo('Combo #1', { '1', '2' }, 0)) == 'userdata' and
        type(A:keybind('Keybind #1', true, 1, 0, false)) == 'userdata' and
        type(A:multicombo('Multicombo #1', { '1', '2', '3' }, { 0 })) == 'userdata' and
        type(A:slider_float('Slider float #1', 0, 180, 0)) == 'userdata' and
        type(A:slider_int('Slider int #1', 0, 180, 0)) == 'userdata' and
        type(A:switch('Switch #1', false)) == 'userdata' and
        type(class) == 'table' and
        type(switch) == 'userdata'
    );

    ui.delete('A');

    return true;
end);

test.new('ui.button', function()
    local ui = require('libs.ui');

    local A = ui.create('A');
    local button = A:button('Button', function() end);

    button:execute();

    button:set_visible(true);
    button:set_visible(false);

    ui.delete('A');

    return true;
end);

test.new('ui.color', function()
    local ui = require('libs.ui');

    local A = ui.create('A');
    local color1 = A:color('Color # 1');
    local color2 = A:color('Color # 2', color_t.new(255, 255, 255, 255), true, true);
    local color3 = A:color('Color # 3', color_t.new(255, 255, 255, 255), false, false);
    local color4 = A:color('Color # 4', color_t.new(255, 255, 255, 255), true, false);
    local color5 = A:color('Color # 5', color_t.new(255, 255, 255, 255), false, true);

    color1:set(color_t.new(255, 255, 255, 255));
    color2:set(color_t.new(255, 255, 255, 255));
    color3:set(color_t.new(255, 255, 255, 255));
    color4:set(color_t.new(255, 255, 255, 255));
    color5:set(color_t.new(255, 255, 255, 255));

    local value_1 = color1:get();
    local value_2 = color2:get();
    local value_3 = color3:get();
    local value_4 = color4:get();
    local value_5 = color5:get();

    assert(
        type(value_1.r) == 'number' and
        type(value_1.g) == 'number' and
        type(value_1.b) == 'number' and
        type(value_1.a) == 'number' and

        type(value_2.r) == 'number' and
        type(value_2.g) == 'number' and
        type(value_2.b) == 'number' and
        type(value_2.a) == 'number' and

        type(value_3.r) == 'number' and
        type(value_3.g) == 'number' and
        type(value_3.b) == 'number' and
        type(value_3.a) == 'number' and

        type(value_4.r) == 'number' and
        type(value_4.g) == 'number' and
        type(value_4.b) == 'number' and
        type(value_4.a) == 'number' and

        type(value_5.r) == 'number' and
        type(value_5.g) == 'number' and
        type(value_5.b) == 'number' and
        type(value_5.a) == 'number'
    );

    color1:set_visible(true);
    color1:set_visible(false);

    color2:set_visible(true);
    color2:set_visible(false);

    color3:set_visible(true);
    color3:set_visible(false);

    color4:set_visible(true);
    color4:set_visible(false);

    color5:set_visible(true);
    color5:set_visible(false);

    ui.delete('A');

    return true;
end);

test.new('ui.combo', function()
    local ui = require('libs.ui');

    local A = ui.create('A');
    local combo1 = A:combo('Combo # 1', { '1', '2', '3' });
    local combo2 = A:combo('Combo # 2', { '1', '2', '3' }, 2);

    assert(
        type(combo1:get()) == 'number' and
        type(combo2:get()) == 'number'
    );

    combo1:set(2);
    combo2:set(1);

    combo1:set_items({ '1' });
    combo2:set_items({ '5' });

    assert(
        type(combo1:get()) == 'number' and
        type(combo2:get()) == 'number'
    );

    combo1:set(0);
    combo2:set(0);

    assert(
        type(combo1:get()) == 'number' and
        type(combo2:get()) == 'number'
    );

    combo1:set_visible(true);
    combo1:set_visible(false);

    combo2:set_visible(true);
    combo2:set_visible(false);

    ui.delete('A');

    return true;
end);

test.new('ui.multicombo', function()
    local ui = require('libs.ui');
    local A = ui.create('A');

    local multicombo1 = A:multicombo('Multicombo # 1', { '1', '2', '3' });
    local multicombo2 = A:multicombo('Multicombo # 2', { '1', '2', '3' }, { 0, 1 });

    assert(
        multicombo1:get(0) == false and
        multicombo2:get(0) == true
    );

    multicombo1:set(0, true);
    multicombo2:set(0, true);

    multicombo1:set_items({ '1', '7' });
    multicombo2:set_items({ '5', '7' });

    assert(
        multicombo1:get(0) == true and
        multicombo2:get(0) == true
    );

    multicombo1:set(0, false);
    multicombo2:set(0, false);

    assert(
        multicombo1:get(1) == false and
        multicombo2:get(1) == true
    );

    multicombo1:set_visible(true);
    multicombo1:set_visible(false);

    multicombo2:set_visible(true);
    multicombo2:set_visible(false);

    ui.delete('A');

    return true;
end);

test.new('ui.keybind', function()
    local ui = require('libs.ui');
    local A = ui.create('A');

    local keybind1 = A:keybind('Keybind # 1');
    local keybind2 = A:keybind('Keybind # 2', true, 1, 1, true);
    local keybind3 = A:keybind('Keybind # 2', false, 0, 0, false);

    assert(
        type(keybind1:get_display_in_list()) == 'boolean' and
        type(keybind1:get_key()) == 'number' and
        type(keybind1:get_type()) == 'number' and
        type(keybind1:is_active()) == 'boolean' and

        type(keybind2:get_display_in_list()) == 'boolean' and
        type(keybind2:get_key()) == 'number' and
        type(keybind2:get_type()) == 'number' and
        type(keybind2:is_active()) == 'boolean' and

        type(keybind3:get_display_in_list()) == 'boolean' and
        type(keybind3:get_key()) == 'number' and
        type(keybind3:get_type()) == 'number' and
        type(keybind3:is_active()) == 'boolean'
    );

    keybind1:set_display_in_list(true);
    keybind1:set_display_in_list(false);

    keybind2:set_display_in_list(true);
    keybind2:set_display_in_list(false);

    keybind3:set_display_in_list(true);
    keybind3:set_display_in_list(false);

    keybind1:set_key(2);
    keybind2:set_key(2);
    keybind3:set_key(2);

    keybind1:set_type(0);
    keybind2:set_type(0);
    keybind3:set_type(0);

    keybind1:set_visible(true);
    keybind1:set_visible(false);
    keybind2:set_visible(true);
    keybind2:set_visible(false);
    keybind3:set_visible(true);
    keybind3:set_visible(false);

    ui.delete('A');
    return true;
end);

test.new('ui.slider_float', function()
    local ui = require('libs.ui');
    local A = ui.create('A');

    local slider_float = A:slider_float('Slider float #1', 0, 100, 50);

    assert(
        type(slider_float.set) == 'function' and
        type(slider_float:get()) == 'number' and
        slider_float:get() == 50
    );

    slider_float:set_visible(true);
    slider_float:set_visible(false);

    ui.delete('A');

    return true;
end);

test.new('ui.slider_int', function()
    local ui = require('libs.ui');
    local A = ui.create('A');

    local slider_int = A:slider_int('Slider int #1', 0, 100, 50);

    assert(
        type(slider_int.set) == 'function' and
        type(slider_int:get()) == 'number' and
        slider_int:get() == 50
    );

    slider_int:set_visible(true);
    slider_int:set_visible(false);

    ui.delete('A');

    return true;
end);

test.new('ui.switch', function()
    local ui = require('libs.ui');
    local A = ui.create('A');

    local class, switch = A:switch('Switch', true, true);
    ---@cast class -check_box_t

    switch:set_visible(true);
    switch:set_visible(false);

    assert(
        type(switch) == 'userdata' and
        type(class) == 'table'
    );

    local a, b = class:switch('Switch group #2', true, true);

    assert(
        type(class.elements) == 'table' and
        type(class.location) == 'string' and
        type(class.name) == 'string' and
        type(class:button('Button #1', function() end)) == 'userdata' and
        type(class:color('Color picker #1', color_t.new(0, 0, 0, 0), true, true)) == 'userdata' and
        type(class:combo('Combo #1', { '1', '2' }, 0)) == 'userdata' and
        type(class:keybind('Keybind #1', true, 1, 0, false)) == 'userdata' and
        type(class:multicombo('Multicombo #1', { '1', '2', '3' }, { 0 })) == 'userdata' and
        type(class:slider_float('Slider float #1', 0, 180, 0)) == 'userdata' and
        type(class:slider_int('Slider int #1', 0, 180, 0)) == 'userdata' and
        type(class:switch('Switch #2', false)) == 'userdata' and
        type(a) == 'table' and
        type(b) == 'userdata'
    );

    ui.delete('A');

    return true;
end);

test.new('ui.connect', function()
    local ui = require('libs.ui');
    local handle = ui.create('A');

    local custom_resolver = handle:switch('ENABLE CUSTOM_RESOZOLVER');
    local resolver_type = handle:combo('Resolver Type', { 'Off', 'Default', 'Extended' });

    custom_resolver:connect({
        {
            master = resolver_type,
            {},
            {},
            {
                iq = handle:slider_int('Resolver iq', 50, 120),
                extrapolation = handle:slider_float('Extrapolation amount', 0, 1),
                {
                    master = handle:switch('Jitter prediction'),
                    {
                        master = handle:slider_int('Prediction amount', 0, 6, 1),
                        [6] = {
                            master = handle:switch('Normalize on high speed'),
                            {
                                master = handle:switch('Visualize prediction'),
                                {
                                    master = handle:color('Color of model', color_t.new(0, 0, 0, 0)),
                                    [color_t.new(1, 1, 1, 1)] = {
                                        master = handle:switch('Penis'),
                                        {
                                            master = handle:keybind('Delta penisov', true, nil, 1),
                                            {
                                                master = handle:switch('PIZDA'),
                                                {
                                                    master = handle:slider_float('KAKASHKE', 0, 1),
                                                    [0.5] = {
                                                        SUKA = handle:switch('SUKA'),
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    });

    return true;
end);

test.main();
