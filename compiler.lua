local math_floor, string_gmatch, string_byte = math.floor, string.gmatch, string.byte;

local keywords = {
    ['0'] = 'КАКАЩКЕ',
    ['1'] = 'БУГАГАЩКЕ'
};

local file = io.open('init.lua');

if not file then
    return;
end;

local code = file:read('*a');
file:close();

---@param value number
---@return string
local function bin(value)
    local result = '';

    repeat
        local remainder = value % 2;
        result = remainder .. result;
        value = math_floor(value / 2);
    until value == 0;

    if result == '' then
        result = '0';
    end;

    return result;
end;

local function compile(str)
    local compiled = '';

    for char in string_gmatch(str, '.') do
        local byte = string_byte(char);
        local binary = bin(byte);

        for digit in string_gmatch(binary, '.') do
            compiled = compiled .. keywords[digit];
        end;
    end;

    return compiled;
end;

print('Starting compilation...');

local compiled = compile(code);

local file = io.open('compiled', 'w');
if not file then
    print('Cant create output file');
    return;
end;

file:write(compiled);
file:close();

print('File was created!');
