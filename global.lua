NATIVE_PRINT = NATIVE_PRINT or print;
NotImplemented = 'NotImplemented';

ffi = require 'ffi'; do
    ffi.cdef [[
        // add cdef declares here
        void* GetModuleHandleA(const char*);
        void* GetProcAddress(void*, const char*);
    ]];
end;

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
