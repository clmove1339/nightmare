local vmt_hook = {}; do
    local list = {};

    local c_hook_mgr = {}; do
        function c_hook_mgr:get_original(index)
            local data = self.orig[index];

            if data ~= nil then
                return data.func;
            end;
        end;

        function c_hook_mgr:attach(index, typestring, fn)
            local data = {};

            local pointer = self.iface[index];
            local address = ffi.cast('void*', self.iface + index);

            data.pointer = pointer;
            data.func = ffi.cast(typestring, pointer);

            ffi.C.VirtualProtect(address, 4, 0x4, self.old_protect);
            self.iface[index] = ffi.cast('intptr_t', ffi.cast(typestring, fn));
            ffi.C.VirtualProtect(address, 4, self.old_protect[0], self.old_protect);

            self.orig[index] = data;
            return data.func;
        end;

        function c_hook_mgr:detach(index)
            local data = self.orig[index];

            if data ~= nil then
                local address = ffi.cast('void*', self.iface + index);

                ffi.C.VirtualProtect(address, 4, 0x4, self.old_protect);
                self.iface[index] = data.pointer;

                ffi.C.VirtualProtect(address, 4, self.old_protect[0], self.old_protect);
                self.orig[index] = nil;

                return true;
            end;

            return false;
        end;

        function c_hook_mgr:detach_all()
            for index, _ in pairs(self.orig) do
                self:detach(index);
            end;
        end;

        c_hook_mgr.__index = c_hook_mgr;
    end;

    function vmt_hook:new(address)
        local this = {
            orig = {},
            old_protect = ffi.new('unsigned long[1]'),
            iface = ffi.cast('intptr_t**', address)[0]
        };

        local hook_mgr = setmetatable(this, c_hook_mgr);
        table.insert(list, hook_mgr);
        return hook_mgr;
    end;

    function vmt_hook:self_destruct()
        for i, hook_mgr in ipairs(list) do
            hook_mgr:detach_all();
        end;
    end;

    register_callback('unload', function()
        vmt_hook:self_destruct();
    end);
end;

return vmt_hook;
