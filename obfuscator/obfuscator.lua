local bit = require('bit') 

local function generate_random_variable()
    return generate_random_string(8)
end

local bit_operations = { 'band', 'bor', 'bxor', 'bnot' }
local comparisons = { '==', '~=', '<', '>', '<=', '>=' }
local max_depth = 3 -- Максимальная глубина вложенности

-- Кэш для функций и переменных
local cache = {
    functions = {},
    variables = {},
}

-- Функция для генерации случайной строки
function generate_random_string(length)
    local alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local str = ''
    for i = 1, length do
        local rand = math.random(#alphabet)
        str = str .. alphabet:sub(rand, rand)
    end
    return str
end

-- Функция для генерации случайной переменной
function generate_random_variable()
    return generate_random_string(8)
end

-- Функция для генерации случайных операций
function generate_random_operation()
    local operations = { '+', '-', '*', '/', '%' }
    local op = operations[math.random(#operations)]
    local var1 = generate_random_variable()
    local var2 = generate_random_variable()
    return var1 .. ' = ' .. var1 .. ' ' .. op .. ' ' .. var2
end

-- Функция для генерации случайных битовых операций
function generate_random_bit_operation()
    local bit_operations = { 'band', 'bor', 'bxor', 'bnot' }
    local op = bit_operations[math.random(#bit_operations)]
    local var1 = generate_random_variable()
    local var2 = generate_random_variable()
    return var1 .. ' = bit.' .. op .. '(' .. var1 .. ', ' .. var2 .. ')'
end

-- Функция для генерации случайных таблиц
function generate_random_table()
    local table_name = generate_random_variable()
    local num_entries = math.random(1, 5)
    local table_entries = {}

    for i = 1, num_entries do
        local key = generate_random_string(4)
        local value = generate_random_string(8)
        table_entries[#table_entries + 1] = '[' .. '"' .. key .. '"] = "' .. value .. '"'
    end

    return 'local ' .. table_name .. ' = {' .. table.concat(table_entries, ', ') .. '}'
end

-- Функция для генерации осмысленных строк
function generate_random_pattern()
    local patterns = {
        '_', 'debug', 'path', '?', '??', '/', '\\', '@', 'engine',
        'create_move', 'interface', 'ffi', 'memory', 'nightmare',
        '-', '=', '1', '0', 'func', 'var', 'value', 'data', 'temp',
        'tmp', 'result', 'response', 'file', 'input', 'output', 'config',
        'handler', 'manager', 'controller', 'service', 'processor',
        'worker', 'queue', 'task', 'event', 'callback', 'notify',
        'update', 'fetch', 'store', 'load', 'save', 'retrieve', 'process',
        'set', 'get', 'clear', 'add', 'remove', 'update', 'check',
        'log', 'print', 'error', 'warn', 'info', 'trace', 'debug',
        'run', 'start', 'stop', 'pause', 'resume', 'initialize',
        'shutdown', 'restart', 'validate', 'execute', 'call', 'invoke'
    }

    for _ = 1, 100 do
        table.insert(patterns, generate_random_string(math.random(4, 16)))
    end

    return patterns[math.random(#patterns)]
end

-- Функция для генерации случайных строк замены
function generate_random_replacement()
    local replacements = {
        ' ', '', '=', '-', '?', '0', '1', 'true', 'false',
        'null', 'undefined', 'none', 'yes', 'no', 'on', 'off',
        'some', 'any', 'all', 'none', 'every', 'single', 'each',
        'some_value', 'other_value', 'example', 'sample', 'demo',
        'test', 'check', 'value1', 'value2', 'value3', 'value4'
    }

    for _ = 1, 100 do
        table.insert(replacements, generate_random_string(math.random(4, 16)))
    end

    return replacements[math.random(#replacements)]
end

-- Функция для генерации случайных условий
function generate_random_condition(depth)
    depth = depth or 1
    local num_vars = math.random(2, 4)
    local condition_lines = {}
    local vars = {}

    for i = 1, num_vars do
        table.insert(vars, generate_random_variable())
    end

    local num_conditions = math.random(1, num_vars - 1)
    local condition_parts = {}

    for i = 1, num_conditions do
        local var1 = vars[math.random(#vars)]
        local var2 = vars[math.random(#vars)]
        local comparison = comparisons[math.random(#comparisons)]
        local condition = var1 .. ' ' .. comparison .. ' ' .. var2
        table.insert(condition_parts, condition)
    end

    if math.random() > 0.5 then
        local bit_op = bit_operations[math.random(#bit_operations)]
        local bit_condition = 'bit.' .. bit_op .. '(' .. vars[math.random(#vars)] .. ', ' .. vars[math.random(#vars)] .. ')'
        table.insert(condition_parts, bit_condition)
    end

    local condition_str = '(' .. table.concat(condition_parts, ' or ') .. ')'
    if math.random() > 0.5 then
        condition_str = '(' .. condition_str .. ')'
    end

    local code = 'if ' .. condition_str .. ' then\n'
    if depth < max_depth then
        code = code .. generate_random_code(depth + 1)
    else
        code = code .. generate_random_operation() .. '\n'
    end
    code = code .. '\nend'

    return code
end

-- Функция для генерации случайных циклов
function generate_random_loop(depth)
    depth = depth or 1
    local var = generate_random_variable()
    local limit_type = math.random(1, 2) -- 1 for fixed, 2 for variable
    local limit

    if limit_type == 1 then
        limit = math.random(5, 20)
    else
        limit = generate_random_variable() -- Use a variable as the loop limit
    end

    local code = 'for ' .. var .. ' = 1, ' .. limit .. ' do\n'
    if depth < max_depth then
        code = code .. generate_random_code(depth + 1)
    else
        code = code .. generate_random_operation() .. '\n'
    end
    code = code .. '\nend'

    return code
end

-- Функция для генерации случайных встроенных вызовов
function generate_random_builtin_call()
    local builtins = {
        math = {
            sqrt = function(var) return 'local ' .. generate_random_variable() .. ' = math.sqrt(' .. var .. ')' end,
            floor = function(var) return 'local ' .. generate_random_variable() .. ' = math.floor(' .. var .. ')' end
        },
        string = {
            find = function(var) return 'local ' .. generate_random_variable() .. ' = string.find(' .. var .. ', "' .. generate_random_pattern() .. '")' end,
            gsub = function(var) return 'local ' .. generate_random_variable() .. ' = string.gsub(' .. var .. ', "' .. generate_random_pattern() .. '", "' .. generate_random_replacement() .. '")' end
        },
        os = {
            time = function() return 'local ' .. generate_random_variable() .. ' = os.time()' end,
            date = function() return 'local ' .. generate_random_variable() .. ' = os.date("%Y-%m-%d")' end
        }
    }

    local lib = {}
    for k in pairs(builtins) do table.insert(lib, k) end
    local selected_lib = lib[math.random(#lib)]

    local funcs = {}
    for k in pairs(builtins[selected_lib]) do table.insert(funcs, k) end
    local func_name = funcs[math.random(#funcs)]

    local var = generate_random_variable()
    return builtins[selected_lib][func_name](var)
end

-- Функция для генерации случайного кода
function generate_random_code(depth)
    depth = depth or 1
    local num_lines = math.random(2, 6)
    local code_lines = {}

    for _ = 1, num_lines do
        local line_type = math.random(1, 10)
        if line_type == 1 then
            table.insert(code_lines, 'local ' .. generate_random_variable() .. ' = ' .. generate_random_string(8))
        elseif line_type == 2 then
            table.insert(code_lines, generate_random_operation())
        elseif line_type == 3 then
            table.insert(code_lines, generate_random_bit_operation())
        elseif line_type == 4 then
            table.insert(code_lines, generate_random_condition(depth))
        elseif line_type == 5 then
            table.insert(code_lines, generate_random_loop(depth))
        elseif line_type == 6 then
            table.insert(code_lines, generate_random_table())
        elseif line_type == 7 then
            table.insert(code_lines, generate_random_builtin_call())
        elseif line_type == 8 then
            table.insert(code_lines, 'local ' .. generate_random_variable() .. ' = ' .. generate_random_variable() .. '()')
        elseif line_type == 9 then
            table.insert(code_lines, generate_random_function())
        elseif line_type == 10 then
            local func_call = 'local ' .. generate_random_variable() .. ' = ' .. generate_random_variable() .. '()'
            table.insert(code_lines, func_call)
        end
    end

    return table.concat(code_lines, '\n')
end

-- Функция для генерации случайных функций
function generate_random_function()
    local func_name = generate_random_string(8) -- No digits in function names
    local param_list = {}
    local num_params = math.random(1, 5)
    for _ = 1, num_params do
        table.insert(param_list, generate_random_variable())
    end
    local params = table.concat(param_list, ', ')

    local code_lines = {
        'local function ' .. func_name .. '(' .. params .. ')',
        generate_random_code(1), -- Recursive call to generate nested code
        '    return ' .. generate_random_variable(),
        'end'
    }

    return table.concat(code_lines, '\n')
end

-- Функция для добавления бесполезного кода
function add_useless_code(text)
    local num_prefix = math.random(5, 15)
    local num_suffix = math.random(5, 15)
    local prefix = ''
    local suffix = ''

    for _ = 1, num_prefix do
        prefix = prefix .. generate_random_function() .. '\n'
    end

    for _ = 1, num_suffix do
        suffix = suffix .. '\n' .. generate_random_function()
    end

    return prefix .. text .. suffix
end

-- Главная функция для обфускации
function obfuscate(text)
    return add_useless_code(text)
end
