local memory = require 'libs.memory';

---@class net_channel_info_t
---@field this INetChannelInfo
local net_channel_info_t = {}; do
    ---@param self net_channel_info_t
    function net_channel_info_t:get_name()
        return ffi.string(self.this:GetName());
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:get_address()
        return ffi.string(self.this:GetAddress());
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:get_time()
        return self.this:GetTime();
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:get_time_connected()
        return self.this:GetTimeConnected();
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:get_buffer_size()
        return self.this:GetBufferSize();
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:get_data_rate()
        return self.this:GetDataRate();
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:is_loopback()
        return self.this:IsLoopback();
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:is_timing_out()
        return self.this:IsTimingOut();
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:is_playback()
        return self.this:IsPlayback();
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_latency(flow)
        return self.this:GetLatency(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_avg_latency(flow)
        return self.this:GetAvgLatency(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_avg_loss(flow)
        return self.this:GetAvgLoss(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_avg_choke(flow)
        return self.this:GetAvgChoke(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_avg_data(flow)
        return self.this:GetAvgData(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_avg_packets(flow)
        return self.this:GetAvgPackets(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_total_data(flow)
        return self.this:GetTotalData(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_total_packets(flow)
        return self.this:GetTotalPackets(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    function net_channel_info_t:get_sequence_nr(flow)
        return self.this:GetSequenceNr(flow);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    ---@param frame_number number
    function net_channel_info_t:is_valid_packet(flow, frame_number)
        return self.this:IsValidPacket(flow, frame_number);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    ---@param frame_number number
    function net_channel_info_t:get_packet_time(flow, frame_number)
        return self.this:GetPacketTime(flow, frame_number);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    ---@param frame_number number
    ---@param group number
    function net_channel_info_t:get_packet_bytes(flow, frame_number, group)
        return self.this:GetPacketBytes(flow, frame_number, group);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    ---@return boolean, number, number
    function net_channel_info_t:get_stream_progress(flow)
        local received = ffi.new('int[1]');
        local total = ffi.new('int[1]');
        local success = self.this:GetStreamProgress(flow, received, total);
        return success, received[0], total[0];
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:get_time_since_last_received()
        return self.this:GetTimeSinceLastReceived();
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    ---@param frame_number number
    function net_channel_info_t:get_command_interpolation_amount(flow, frame_number)
        return self.this:GetCommandInterpolationAmount(flow, frame_number);
    end;

    ---@param self net_channel_info_t
    ---@param flow number
    ---@param frame_number number
    ---@return number, number
    function net_channel_info_t:get_packet_response_latency(flow, frame_number)
        local latency_msecs = ffi.new('int[1]');
        local choke = ffi.new('int[1]');
        self.this:GetPacketResponseLatency(flow, frame_number, latency_msecs, choke);
        return latency_msecs[0], choke[0];
    end;

    ---@param self net_channel_info_t
    ---@return number, number, number
    function net_channel_info_t:get_remote_framerate()
        local frame_time = ffi.new('float[1]');
        local frame_time_std_deviation = ffi.new('float[1]');
        local frame_start_time_std_deviation = ffi.new('float[1]');
        self.this:GetRemoteFramerate(frame_time, frame_time_std_deviation, frame_start_time_std_deviation);
        return frame_time[0], frame_time_std_deviation[0], frame_start_time_std_deviation[0];
    end;

    ---@param self net_channel_info_t
    function net_channel_info_t:get_timeout_seconds()
        return self.this:GetTimeoutSeconds();
    end;

    net_channel_info_t.__index = net_channel_info_t;
end;

local engine_client = {}; do
    function engine_client:get_net_channel_info()
        local net_channel_info = IEngineClient:GetNetChannel();

        if (net_channel_info == nil) then
            return nil;
        end;

        return setmetatable({ this = INetChannelInfo(net_channel_info) }, net_channel_info_t);
    end;

    function engine_client:get_local_player()
        return IEngineClient:GetLocalPlayer();
    end;
end;

return engine_client;
