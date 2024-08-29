math.randomseed(os.time());
local files = require 'obfuscator.file_manager';
require 'obfuscator.obfuscator';

local code = files.read('init.lua');
if not code then
    print('File read error');
    return;
end;

local obfuscated = obfuscate(code);
if not obfuscated then
    print('Obfuscation error!');
    return;
end;

files.save('obfuscator/output/obfuscated.lua', obfuscated);
