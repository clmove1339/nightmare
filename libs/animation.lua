--- Я рот сейза долбил
--- Где нахуй хоть один метод для работы с анимациями пидорас
local memory = require 'libs.memory';

local animation = { cache = {} }; do
    ---@private
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

    ---@public
    ---@param a number
    ---@param b number|boolean
    ---@param t number
    ---@param easing_fn? function
    ---@return number
    function animation:interp(a, b, t, easing_fn)
        easing_fn = easing_fn or linear;

        if type(b) == 'boolean' then
            b = b and 1 or 0;
        end;

        return solve(easing_fn, a, b, get_clock(), t);
    end;

    ---@param name any
    ---@param a? number
    ---@param b number|boolean
    ---@param t? number
    ---@return number
    function animation:new(name, a, b, t)
        local cache = animation.cache;
        a = a or 0; t = t or .05;

        if not cache[name] then
            cache[name] = a;
        else
            cache[name] = animation:interp(cache[name], b, t);

            return cache[name];
        end;

        return a;
    end;

    ---@param name any
    ---@param value number
    function animation:set(name, value)
        if animation.cache[name] then
            animation.cache[name] = value or 0;
        end;
    end;

    function animation:delete(name)
        animation.cache[name] = nil;
    end;
end;

return animation;
