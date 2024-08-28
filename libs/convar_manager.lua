local convar_manager = {
    ---@type convar_object[]
    objects = {},
}; do
    ---@generic T
    ---@param index string
    ---@param elements {[1]: string, [2]: T, [3]: T}[]
    ---@param controller check_box_t
    convar_manager.new = function(index, elements, controller)
        if not convar_manager.objects[index] then
            ---@class convar_object
            convar_manager.objects[index] = {
                index = index,
                elements = elements,
                controller = controller,
                old_value = false,
            };
        end;

        return convar_manager.objects[index];
    end;

    convar_manager.handler = function()
        for _, object in pairs(convar_manager.objects) do
            local enabled = object.controller:get();

            if enabled ~= object.old_value then
                object.old_value = enabled;

                for _, element in pairs(object.elements) do
                    local type = typeof(element[2]);
                    local cvar_name = element[1];
                    local set = enabled and element[2] or element[3];

                    if type == 'boolean' then
                        cvars[cvar_name]:set_bool(set);
                    elseif type == 'string' then
                        cvars[cvar_name]:set_string(set);
                    elseif type == 'number' then
                        if set % 1 ~= 0 then
                            cvars[cvar_name]:set_float(set);
                        else
                            cvars[cvar_name]:set_int(set);
                        end;
                    end;
                end;
            end;
        end;
    end;

    register_callback('paint', function()
        xpcall(convar_manager.handler, print);
    end);
end;


return convar_manager;
