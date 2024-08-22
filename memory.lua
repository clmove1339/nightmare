local memory = {}; do
    ---@private
    local class = {}; do
        ---@class class_t
        ---@field private this ffi.ctype*
        ---@field private ptr number
        local class_t = {
            ---@private
            __call = function(self, instance)
                local functions = self.__functions;

                if (not instance) then
                    return;
                end;

                local ptr = ffi.cast('void***', instance);

                if (not self.__pointers) then
                    self.__pointers = {};

                    for fn_name, data in pairs(functions) do
                        local casted_fn = ffi.cast(data[2], ptr[0][data[1]]);

                        self.__pointers[fn_name] = function(class, ...)
                            return casted_fn(class.this, ...);
                        end;
                    end;
                end;

                return setmetatable({ this = ptr, ptr = ffi.cast('uintptr_t', ptr) }, { __index = self.__pointers });
            end
        };

        ---@generic T
        ---@param fns T
        function class:new(fns)
            return setmetatable({ __functions = fns }, class_t);
        end;
    end;

    local function vtable_thunk(index, ...)
        local ctype = ffi.typeof(...);

        return function(instance, ...)
            assert(instance ~= nil, 'invalid instance');

            local vtable = ffi.cast('void***', instance);
            local vfunc = ffi.cast(ctype, vtable[0][index]);

            return vfunc(instance, ...);
        end;
    end;

    local function vtable_bind(module_name, interface_name, index, ...)
        local addr = utils.create_interface(module_name, interface_name);
        assert(addr, 'invalid interface');

        local ctype = ffi.typeof(...);

        local vtable = ffi.cast('void***', addr);
        local vfunc = ffi.cast(ctype, vtable[0][index]);

        return function(...)
            return vfunc(vtable, ...);
        end;
    end;

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

    function memory:class(fns)
        return class:new(fns);
    end;

    function memory:interface(module, name, fns)
        local ptr = self:create_interface(module, name);
        assert(ptr, 'failed to create interface');

        return class:new(fns)(ptr);
    end;

    function memory:get_vfunc(arg, ...)
        if (type(arg) == 'number') then
            return vtable_thunk(arg, ...);
        end;

        if (type(arg) == 'string') then
            return vtable_bind(arg, ...);
        end;
    end;
end;


return memory;
