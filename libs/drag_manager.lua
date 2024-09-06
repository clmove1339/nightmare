--[[
    1. Добавить игнор лист
    2. Добавить получение позиции курсора с никсвара
    3. Добавить лерп векторов
    4. Добавить каллбек на объект ( выполнение определенного кода если какой-то объект был драгнут / Находится в этом состоянии )
]]

local input = require 'libs.input';

---@class DragObject
---@field id string
---@field origin vec2_t
---@field size vec2_t
---@field animated boolean|nil
---@field move fun(self: DragObject, goal: vec2_t): nil Moves the object to the specified location
---@field set_x fun(self: DragObject, x: number): nil Moves the object to the specified location by x
---@field set_y fun(self: DragObject, y: number): nil Moves the object to the specified location by y
---@field move_by fun(self: DragObject, dx: number, dy: number): nil Moves an object by a specified distance
---@field move_to fun(self: DragObject, x: number, y: number): nil Moves the object to the specified location
---@field resize fun(self: DragObject, width: number, height: number): nil Changes the size of the object
---@field set_width fun(self: DragObject, width: number): nil Changes the width of the object
---@field set_height fun(self: DragObject, height: number): nil Changes the height of the object
---@field intersects fun(self: DragObject, other: DragObject): boolean Checks if two objects intersect
---@field get_center fun(self: DragObject): vec2_t Calculates the center of the object
---@field contains fun(self: DragObject, point: vec2_t): boolean Checks whether an object contains a point

local drag_manager = {
    ---@type DragObject[]
    objects = {},
    ---@type DragObject[]
    priority_queue = {},
    ---@type nil|DragObject
    active_object = nil,
    mouse_hold_duration = 0,
    touch_offset = vec2_t.new(0, 0),
}; do
    local drag_object = {
        ---@param self DragObject
        ---@param goal vec2_t
        move = function(self, goal)
            goal = goal or self.origin;
            self.origin = goal;
        end,

        ---@param self DragObject
        ---@param x number
        set_x = function(self, x)
            x = x or self.origin.x;
            self.origin.x = x;
        end,

        ---@param self DragObject
        ---@param y number
        set_y = function(self, y)
            y = y or self.origin.y;
            self.origin.y = y;
        end,

        ---@param self DragObject
        ---@param dx number
        ---@param dy number
        move_by = function(self, dx, dy)
            dx = dx or 0;
            dy = dy or 0;

            self.origin = self.origin + vector(dx, dy);
        end,

        ---@param self DragObject
        ---@param x number
        ---@param y number
        move_to = function(self, x, y)
            x = x or self.origin.x;
            y = y or self.origin.y;

            self.origin = vec2_t.new(x, y);
        end,

        ---@param self DragObject
        ---@param width number
        ---@param height number
        resize = function(self, width, height)
            width = width or self.size.x;
            height = height or self.size.y;

            if self.animated then
                self.size = self.size:lerp(vector(width, height), 1);
                return;
            end;

            self.size = vector(width, height);
        end,

        ---@param self DragObject
        ---@param width number
        set_width = function(self, width)
            width = width or self.size.x;

            if self.animated then
                self.size.x = math.lerp(self.size.x, width, 1);
                return;
            end;

            self.size.x = width;
        end,

        ---@param self DragObject
        ---@param height number
        set_height = function(self, height)
            height = height or self.size.y;

            if self.animated then
                self.size.y = math.lerp(self.size.y, height, 1);
                return;
            end;

            self.size.y = height;
        end,

        ---@param self DragObject
        ---@param other DragObject
        ---@return boolean
        intersects = function(self, other)
            local al, ar, at, ab = self.origin.x, self.origin.x + self.size.x, self.origin.y, self.origin.y + self.size.y;
            local bl, br, bt, bb = other.origin.x, other.origin.x + other.size.x, other.origin.y, other.origin.y + other.size.y;

            return al < br and ar > bl and at < bb and ab > bt;
        end,

        ---@param self DragObject
        ---@return vec2_t
        get_center = function(self)
            return vec2_t.new(self.origin.x + self.size.x / 2, self.origin.y + self.size.y / 2);
        end,

        ---@param self DragObject
        ---@param point vec2_t
        ---@return boolean
        contains = function(self, point)
            return point.x >= self.origin.x and point.x <= (self.origin.x + self.size.x) and
                point.y >= self.origin.y and point.y <= (self.origin.y + self.size.y);
        end,
    };

    ---@param object DragObject
    ---@return boolean
    drag_manager.is_cursor_in_bounds = function(object)
        local cursor_position = utils.get_mouse_position();
        local origin = object.origin;
        local size = object.size;

        local is_x_in_bounds = cursor_position.x >= origin.x and cursor_position.x <= (origin.x + size.x);
        local is_y_in_bounds = cursor_position.y >= origin.y and cursor_position.y <= (origin.y + size.y);

        return is_x_in_bounds and is_y_in_bounds;
    end;

    drag_manager.update_mouse_hold_duration = function()
        drag_manager.mouse_hold_duration = input:is_key_pressed(0x1) and drag_manager.mouse_hold_duration + 1 or 0;
    end;

    ---@return boolean
    drag_manager.is_mouse_button_held = function()
        return drag_manager.mouse_hold_duration > 1;
    end;

    ---@return boolean
    drag_manager.is_mouse_button_pressed = function()
        return drag_manager.mouse_hold_duration == 1;
    end;

    drag_manager.main = function()
        local cursor_position = utils.get_mouse_position();
        drag_manager.update_mouse_hold_duration();

        if drag_manager.is_mouse_button_pressed() then
            for i, object in pairs(drag_manager.priority_queue) do
                if not object then
                    goto continue;
                end;

                if drag_manager.is_cursor_in_bounds(object) then
                    drag_manager.active_object = object;
                    drag_manager.touch_offset = object.origin - cursor_position;
                    table.move(drag_manager.priority_queue, i, 1);
                    break;
                end;
                ::continue::
            end;
        elseif drag_manager.is_mouse_button_held() and drag_manager.active_object then
            drag_manager.active_object:move(cursor_position + drag_manager.touch_offset);
        elseif not drag_manager.is_mouse_button_held() then
            drag_manager.active_object = nil;
        end;
    end;

    ---@param id string
    ---@param origin? vec2_t
    ---@param size? vec2_t
    ---@param animated? boolean
    ---@return DragObject
    drag_manager.new = function(id, origin, size, animated)
        if not drag_manager.objects[id] then
            drag_manager.objects[id] = setmetatable({
                id = id,
                origin = origin or vec2_t.new(0, 0),
                size = size or vec2_t.new(100, 100),
                animated = animated or false,
            }, { __index = drag_object });

            table.insert(drag_manager.priority_queue, drag_manager.objects[id]);
        end;

        return drag_manager.objects[id];
    end;

    ---@param id string
    drag_manager.destroy = function(id)
        if drag_manager.objects[id] then
            drag_manager.objects[id] = nil;

            local i = drag_manager.find(id);
            if i then
                table.remove(drag_manager.priority_queue, i);
            end;
        end;
    end;

    ---@param id string
    ---@return DragObject
    drag_manager.get = function(id)
        return drag_manager.objects[id];
    end;

    ---@param id string
    ---@return integer|nil, DragObject|nil
    drag_manager.find = function(id)
        for i, object in pairs(drag_manager.priority_queue) do
            if object.id == id then
                return i, object;
            end;
        end;
    end;

    ---@param id string
    drag_manager.set_active = function(id)
        local object = drag_manager.get(id);
        local i = drag_manager.find(id);
        drag_manager.active_object = object;
        table.move(drag_manager.priority_queue, i, 1);
    end;

    ---Creates a new unnamed field that is processed as an object and linked to the id of an existing object ( Also top most )
    ---@param origin vec2_t: Origin vector
    ---@param size vec2_t: Size vector
    ---@param id string: ID of the linked object
    ---@return boolean value: Was there a click in the field area of the lambda object
    drag_manager.lambda_object = function(origin, size, id)
        if not drag_manager.is_mouse_button_pressed() then
            return false;
        end;

        local cursor_position = utils.get_mouse_position();
        local lambda = { size = size, origin = origin };

        ---@diagnostic disable: missing-fields
        if drag_manager.is_cursor_in_bounds(lambda) then
            drag_manager.set_active(id);
            drag_manager.touch_offset = origin - cursor_position;
        end;

        return true;
    end;

    register_callback('paint', function()
        drag_manager.main();
    end);
end;

return drag_manager;
