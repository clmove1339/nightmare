local function get_func_address(fn)
    local void = ffi.cast('void(__thiscall*)()', fn);
    local id = ffi.cast('unsigned long*', void)[0];

    return id;
end;

local function check_by_hook(fn, args, signature)
    local exec = {};
    local abbs = {
        ['call'] = 'c',
        ['line'] = 'l',
        ['return'] = 'r',
    };

    debug.sethook(function(event)
        table.insert(exec, abbs[event]);
    end, 'clr');
    fn(unpack(args));
    debug.sethook();

    return signature == table.concat(exec);
end;

local function get_function_signature(fn)
    local info = debug.getinfo(fn);

    if not info then
        return nil, 'Не удалось получить информацию о функции';
    end;

    local name = info.name or 'anonymous';

    local params = {};
    for i = 1, info.nparams do
        table.insert(params, 'arg' .. i);
    end;

    if info.isvararg then
        table.insert(params, '...');
    end;

    local signature = string.format('function %s(%s)', name, table.concat(params, ', '));

    return signature;
end;

---@param fn function
---@param args table
---@param should_be_lua boolean
---@param signature? string
---@return boolean, string
local function is_function_hooked(fn, args, should_be_lua, signature)
    local can_be_dumped, dump_result = pcall(string.dump, fn);
    local is_c_function = debug.getinfo(fn, 'S').what == 'C';
    local is_builtin_function = tostring(fn):find('builtin') ~= nil;
    local is_actual_function = type(fn) == 'function';
    local defined_in_c = debug.getinfo(fn).lastlinedefined == -1;
    local can_get_address, address = pcall(get_func_address, fn);
    local has_meta = debug.getmetatable(fn);
    local can_set_fenv, setfenv_result = pcall(setfenv, fn, {});
    local by_hook_check = check_by_hook(fn, args, 'lclclc');
    local can_get_index, index_msg = pcall(function() return fn.__index; end);
    local can_rawset = pcall(rawset, fn, 'PISKI', 'POPKI');
    local can_rawget = pcall(rawget, fn, 'PISKI', 'POPKI');
    local can_rawlen, msg = pcall(function() a = #fn; end);

    if can_rawlen then
        return true, 'rawlen error';
    end;

    if tostring(getmetatable(fn)) ~= 'nil' then
        return true, 'tostring getmetatable error';
    end;

    if getmetatable(fn) ~= nil then
        return true, 'type getmetatable error';
    end;

    if can_rawget then
        return true, 'rawget error';
    end;

    if can_rawset then
        return true, 'rawset error';
    end;

    if can_get_index then
        return true, 'variable error';
    elseif index_msg:find(" attempt to index upvalue 'fn' %(a function value%)") == nil then
        return true, 'invalid variable error';
    end;

    if not should_be_lua and not by_hook_check then
        return true, 'debug.sethook error';
    end;

    if not can_set_fenv then
        if setfenv_result:find('table') then
            return true, 'setfenv error';
        end;
        if should_be_lua then
            return true, 'setfenv error';
        end;
    end;

    if dump_result:find('table') then
        return true, 'string.dump error';
    end;

    if has_meta then
        return true, 'metatable error';
    end;

    if not can_get_address then
        return true, 'address error';
    end;

    if defined_in_c == should_be_lua then
        return true, 'definition error';
    end;

    if type({}) == 'function' then
        return true, 'table error';
    end;

    if signature then
        if signature ~= get_function_signature(fn) then
            return true, 'signature error';
        end;
    end;

    if not is_actual_function then
        return true, 'type error';
    end;

    if is_c_function and should_be_lua then
        return true, 'debug.getinfo error';
    end;

    if can_be_dumped and not should_be_lua then
        return true, 'string.dump error';
    end;

    if should_be_lua == is_builtin_function then
        return true, 'tostring error';
    end;

    return false;
end;

local function protect()
    local trigger = false;
    local C_signature = 'function anonymous(...)';

    local lambda = function() end;

    local checks = {
        { is_function_hooked(debug.getinfo, { 0 }, false, C_signature) },
        { is_function_hooked(loadstring, { 'a=0' }, false, C_signature) },
        { is_function_hooked(type, { 1 }, false, C_signature) },
        { is_function_hooked(ffi.cast, { 'int', 1 }, false, C_signature) },
        { is_function_hooked(setfenv, { lambda, {} }, false, C_signature) },
        { is_function_hooked(lambda, { nil }, true) },
    };

    for check_id, check in ipairs(checks) do
        local result, error = check[1], check[2];
        if (result) then
            print(string.format('failed #%d (reason: %s)', check_id, error));
            trigger = true;
        else
            print(string.format('success %d', check_id));
        end;
    end;

    return trigger;
end;

if protect() then
    return;
else
    print('All is okey');
end;
