NATIVE_PRINT = NATIVE_PRINT or print;
NotImplemented = 'NotImplemented';
unpack = unpack or table.unpack;
table.unpack = unpack;

ffi = require 'ffi'; do
    ffi.cdef [[
        void* GetModuleHandleA(const char*);
        void* GetProcAddress(void*, const char*);
    ]];
end;

---Enhanced print function
---@param ... any
function print(...)
    local args = { ... };
    for i = 1, #args do
        local arg = args[i];
        NATIVE_PRINT(tostring(arg));
    end;
end;

---Print formatted string
---@param ... any
function printf(...)
    print(string.format(...));
end;

---Clamp a number between mn and mx
---@param x number
---@param mn number
---@param mx number
---@return number
math.clamp = function(x, mn, mx)
    return x <= mn and mn or (x >= mx and mx or x);
end;

---Linear interpolation between a and b with t
---@param a number
---@param b number
---@param t number
---@return number
math.lerp = function(a, b, t)
    return a + (b - a) * t;
end;

---Initialize random seed
math.randomize = function()
    math.randomseed(os.time());
end;

---Check if a number is within a specific range
---@param x number
---@param mn number
---@param mx number
---@return boolean
function math.inrange(x, mn, mx)
    return x >= mn and x <= mx;
end;

---Round a number to the nearest integer or to a specific number of decimal places
---@param num number
---@param idp integer|nil @decimal places (optional)
---@return number
function math.round(num, idp)
    local mult = 10 ^ (idp or 0);
    return math.floor(num * mult + 0.5) / mult;
end;

---Measures the average time taken to execute a function.
---The `iterations` parameter increases the execution time, allowing for more stable measurements.
---The `accuracy` parameter increases the precision of the result by running the benchmark multiple times and averaging the results.
---@param fn function The function to benchmark.
---@param iterations? integer The number of times the function should be executed within a single benchmark run.
---@param accuracy? integer The number of times the benchmark should be repeated to improve accuracy. Defaults to 5 if not provided.
---@param ... any Additional arguments to pass to the benchmarked function.
---@return number time The average time taken for the function to execute.
function benchmark(fn, iterations, accuracy, ...)
    local avg = 0;
    local accuracy = accuracy or 5;
    local iterations = iterations or 10;
    local args = { ... };

    for _ = 1, accuracy do
        local start_time = os.clock();
        if #args ~= 0 then
            for i = 1, iterations do
                fn(..., i);
            end;
        else
            for i = 1, iterations do
                fn(i);
            end;
        end;
        local end_time = os.clock();
        avg = avg + end_time - start_time;
    end;

    return avg / accuracy;
end;

---Swap two elements in a table
---@param list table
---@param a any
---@param b any
table.swap = function(list, a, b)
    list[a], list[b] = list[b], list[a];
end;

---Move an element from one position to another within a table
---@param list table
---@param from number
---@param to number
---@diagnostic disable-next-line: duplicate-set-field
table.move = function(list, from, to)
    local value = list[from];

    table.remove(list, from);
    table.insert(list, to, value);
end;
