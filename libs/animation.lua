local memory = require 'libs.memory';

local cache = {
    -- [name] = 0 - example
};

local animation = {}; do
    --- @private
    local native_GetTimescale = memory:get_vfunc('engine.dll', 'VEngineClient014', 91, 'float(__thiscall*)(void*)');

    local abs, floor, ceil = math.abs, math.floor, math.ceil;

    local function linear(t, b, c, d)
        return c * t / d + b;
    end;

    local function solve(easing_fn, prev, new, clock, duration)
        if type(new) == 'boolean' then new = new and 1 or 0; end;
        if type(prev) == 'boolean' then prev = prev and 1 or 0; end;

        prev = easing_fn(clock, prev, new - prev, duration);

        if type(prev) == 'number' then
            if abs(new - prev) < .01 then
                return new;
            end;

            local fmod = prev % 1;

            if fmod < .001 then
                return floor(prev);
            end;

            if fmod > .999 then
                return ceil(prev);
            end;
        end;

        return prev;
    end;

    local function get_clock()
        return globals.frame_time / native_GetTimescale();
    end;

    --- @public
    ---@param a number
    ---@param b number|boolean
    ---@param t number
    ---@param easing_fn function|nil
    ---@return number
    function animation:interp(a, b, t, easing_fn)
        easing_fn = easing_fn or linear;

        if type(b) == 'boolean' then
            b = b and 1 or 0;
        end;

        return solve(easing_fn, a, b, get_clock(), t);
    end;

    -- На говнокодил шо сисечки писечки
    ---@param name string
    ---@param a number|nil
    ---@param b number|boolean
    ---@param t number|nil
    function animation:new(name, a, b, t)
        a = a or 0; t = t or .05;

        if not cache[name] then
            cache[name] = a;
        else
            cache[name] = animation:interp(cache[name], b, t);

            return cache[name];
        end;

        return 0;
    end;
end;

return animation;
