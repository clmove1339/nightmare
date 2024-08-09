-- Я СПИДОЗНАЯ СКОВОРОДКА
require('global');

local test = {}; do
    ---@type table< string, table<string, function> >
    list = {};
    workspace = nil;

    test.set_workspace = function(name)
        workspace = name;
    end;

    test.new = function(name, fn)
        if not workspace then
            return;
        end;

        if not list[workspace] then
            list[workspace] = {};
        end;

        list[workspace][name] = fn;
    end;

    test.done = function(workspace)
        if not workspace then
            return;
        end;

        local result = { total = 0, passed = 0, time = 0 };

        for name, fn in pairs(list[workspace]) do
            local start_time = os.clock();
            local status = pcall(fn);
            local end_time = os.clock();
            local delta = (end_time - start_time) * 1000;
            result.total = result.total + 1;
            result.time = result.time + delta;

            if status == true then
                printf('%s test was passed in %.1f ms', name, delta);
                result.passed = result.passed + 1;
            else
                printf('%s test was failed in %.1f ms', name, delta);
            end;
        end;

        return result;
    end;

    test.main = function(workspace)
        engine.execute_client_cmd('clear');

        if workspace then
            test.done(workspace);
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
    local ui = require('ui');
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

    ui.delete('A');

    return true;
end);

test.new('ui.button', function()
    local ui = require('ui');

    local A = ui.create('A');
    local button = A:button('Button', function()
        -- Аллах акбар
    end);

    button:execute();

    ui.delete('A');

    return true;
end);

test.new('ui.color', function()
    local ui = require('ui');

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

    ui.delete('A');

    return true;
end);

test.new('ui.combo', function()
    local ui = require('ui');

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

    ui.delete('A');

    return true;
end);

test.new('ui.keybind', function()
    local ui = require('ui');
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

    ui.delete('A');
    return true;
end);

test.main();
