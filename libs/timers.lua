---@class timer
---@field id any
---@field start_time number
---@field duration number
---@field callback function
---@field destroy_after boolean
---@field is_paused boolean
---@field remaining_time number|nil
---@field reset fun(self: timer)
---@field delete fun(self: timer)
---@field pause fun(self: timer)
---@field resume fun(self: timer)
---@field get_progress fun(self: timer): number

local timers = { objects = {} }; do
    local timer_object = {
        ---@param self timer
        reset = function(self)
            self.start_time = globals.real_time;
        end,

        ---@param self timer
        delete = function(self)
            timers.objects[self.id] = nil;
        end,

        ---@param self timer
        pause = function(self)
            if not self.is_paused then
                self.remaining_time = self.duration - (globals.real_time - self.start_time);
                self.is_paused = true;
            end;
        end,

        ---@param self timer
        get_progress = function(self)
            if self.is_paused then
                return (self.duration - self.remaining_time) / self.duration;
            else
                return (globals.real_time - self.start_time) / self.duration;
            end;
        end,

        ---@param self timer
        resume = function(self)
            if self.is_paused then
                self.start_time = globals.real_time - (self.duration - self.remaining_time);
                self.is_paused = false;
                self.remaining_time = nil;
            end;
        end,
    };

    ---@param id any
    ---@param duration number
    ---@param callback function
    ---@param destroy_after boolean
    timers.new = function(id, duration, callback, destroy_after)
        if not timers.objects[id] then
            timers.objects[id] = setmetatable({
                id = id,
                start_time = globals.real_time,
                duration = duration or 1,
                callback = callback or function() end,
                destroy_after = destroy_after ~= false,
                is_paused = false,
                remaining_time = nil,
            }, { __index = timer_object });
        end;
    end;

    timers.handler = function()
        local real_time = globals.real_time;

        for id, timer in pairs(timers.objects) do
            if not timer.is_paused then
                local time_elapsed = real_time - timer.start_time;

                if time_elapsed >= timer.duration then
                    timer.callback();

                    if timer.destroy_after then
                        timers.objects[id] = nil;
                    else
                        timer.start_time = real_time;
                    end;
                end;
            end;
        end;
    end;

    register_callback('paint', timers.handler);
end;

return timers;
