local memory = {}; do
    ---@public
    function memory:create_interface(library, name)
        local handle = ffi.C.GetModuleHandleA(library);

        if (handle) then
            local fn = ffi.C.GetProcAddress(handle, 'CreateInterface');

            if (fn) then
                return ffi.cast('void* (*) (const char*, int)', fn)(name, 0);
            end;
        end;

        return nil;
    end;
end;


return memory;
