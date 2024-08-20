NATIVE_PRINT = NATIVE_PRINT or print;
NotImplemented = 'NotImplemented';

function print(...)
    local args = { ... };
    for i = 1, #args do
        local arg = args[i];
        NATIVE_PRINT(tostring(arg));
    end;
end;

function printf(...)
    print(string.format(...));
end;
