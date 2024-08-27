local inspect = require 'libs.inspect';
local fraction = 1 / 255;

local function concat(...)
    local text, args = '', { ... };

    for i = 1, #args do
        local data = args[i];

        if type(data) == 'table' then
            data = inspect(data);
        end;

        text = string.format('%s %s', text, data);
    end;

    return text:sub(2, #text);
end;

render.fonts = {
    DEFAULT = render.setup_font('C:\\Windows\\Fonts\\Verdana.ttf', 12),
    BOLD = render.setup_font('C:\\Windows\\Fonts\\Verdanab.ttf', 12)
};

local function rgba(hex)
    hex = hex:gsub('#', '');

    local r = tonumber(hex:sub(1, 2), 16);
    local g = tonumber(hex:sub(3, 4), 16);
    local b = tonumber(hex:sub(5, 6), 16);
    local a = tonumber(hex:sub(7, 8), 16) or 255;

    return r, g, b, a;
end;

function render.measure_text(font, ...)
    local text = concat(...);

    return render.calc_text_size(text:gsub('\a(%x%x%x%x%x%x%x%x)', ''):gsub('\adefault', ''), font);
end;

local o_render_text = render.text;

local function render_text(text, font, pos, color, size)
    local r, g, b, a = color.r, color.g, color.b, color.a;

    local position = vec2_t.new(pos.x, pos.y);

    if color == color_t.new(.1, .1, .1, color.a) then
        return render.text(text:gsub('\a(%x%x%x%x%x%x%x%x)', ''):gsub('\adefault', ''), font, position, color, size);
    end;

    if text:find('\a') then
        local alpha_mult = color.a;

        for pattern in string.gmatch(text, '\a?[^\a]+') do
            local text = pattern:match('^\adefault(.-)$');

            if text ~= nil then
                o_render_text(text, font, position, color_t.new(r, g, b, a * alpha_mult));
                position.x = position.x + render.calc_text_size(text, font).x;
            else
                local clr, text = pattern:match('^\a(%x%x%x%x%x%x%x%x)(.-)$');

                if clr ~= nil then
                    local r, g, b, a = rgba(clr);

                    r = r * fraction;
                    g = g * fraction;
                    b = b * fraction;
                    a = a * fraction;

                    o_render_text(text, font, position, color_t.new(r, g, b, a * alpha_mult));
                    position.x = position.x + render.calc_text_size(text, font).x;
                else
                    o_render_text(pattern, font, position, color_t.new(r, g, b, a * alpha_mult));
                    position.x = position.x + render.calc_text_size(pattern, font).x;
                end;
            end;
        end;

        return;
    end;

    return o_render_text(text, font, position, color, size);
end;

function render.text(font, position, color, flags, ...)
    local text = concat(...);

    local position = vec2_t.new(position.x, position.y);

    local shadow_color = color_t.new(.1, .1, .1, color.a * .5);

    if flags:find('c') then
        local text_size = render.measure_text(font, text);

        position.x = position.x - text_size.x * .5;
        -- position.y = position.y - text_size.y * .5;
    end;

    if flags:find('s') then
        shadow_color.a = color.a * 0.75;
        render_text(text, font, vec2_t.new(position.x + 1, position.y + 1), shadow_color);
    end;

    render_text(text, font, position, color);
end;

local function lerp(a, b, t)
    local delta = b - a;

    if type(delta) == 'number' then
        if math.abs(delta) < 0.005 then
            return b;
        end;
    end;

    return delta * t + a;
end;

function render.gradient_text(font, position, color_a, color_b, flags, ...)
    position = vec2_t.new(position.x, position.y);
    flags = flags or '';

    local text = concat(...);

    if flags:find('r') then
        position.x = position.x - render.measure_text(font, text).x;
    end;

    local animated = flags:find('a');

    local x = 0;

    for idx = 1, #text do
        local letter = text:sub(idx, idx);
        local letter_size = render.measure_text(font, letter);

        local ptr = idx / #text;
        local animate = math.sin(math.abs(-math.pi + (globals.real_time - ptr) % (math.pi * 2)));
        local time = animated and animate or ptr;

        local color = color_t.new(
            lerp(color_a.r, color_b.r, time),
            lerp(color_a.g, color_b.g, time),
            lerp(color_a.b, color_b.b, time),
            lerp(color_a.a, color_b.a, time)
        );

        render.text(font, position + vec2_t.new(x, 0), color, flags, letter);

        x = x + letter_size.x;
    end;
end;

return render;
