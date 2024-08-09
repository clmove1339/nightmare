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

        local result = { total = 0, passed = 0 };

        for name, fn in pairs(list[workspace]) do
            result.total = result.total + 1;
            local start_time = os.clock();
            local status = fn();
            local end_time = os.clock();
            local delta = end_time - start_time * 1000;

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
        if workspace then
            test.done(workspace);
        else
            for workspace, _ in pairs(list) do
                local result = test.done(workspace);
                if not result then
                    goto continue;
                end;

                printf('%s out of %s tests of the "%s" workspace were successful', result.passed, result.total, workspace);
                ::continue::
            end;
        end;
    end;
end;

test.set_workspace('ui');

test.new('ui.create', function()
    local ui = require('ui');

    local main = ui.create('Main');
    local misc = ui.create('Misc');

    return false;
end);

test.main();
