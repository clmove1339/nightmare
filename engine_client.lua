local memory = require 'memory';

local INetChannelInfo = memory:class({
    GetName = { 0, 'const char*(__thiscall*)(void*)' },
    GetAddress = { 1, 'const char*(__thiscall*)(void*)' },
    GetTime = { 2, 'float(__thiscall*)(void*)' },
    GetTimeConnected = { 3, 'float(__thiscall*)(void*)' },
    GetBufferSize = { 4, 'int(__thiscall*)(void*)' },
    GetDataRate = { 5, 'int(__thiscall*)(void*)' },
    IsLoopback = { 6, 'bool(__thiscall*)(void*)' },
    IsTimingOut = { 7, 'bool(__thiscall*)(void*)' },
    IsPlayback = { 8, 'bool(__thiscall*)(void*)' },
    GetLatency = { 9, 'float(__thiscall*)(void*, int)' },
    GetAvgLatency = { 10, 'float(__thiscall*)(void*, int)' },
    GetAvgLoss = { 11, 'float(__thiscall*)(void*, int)' },
    GetAvgChoke = { 12, 'float(__thiscall*)(void*, int)' },
    GetAvgData = { 13, 'float(__thiscall*)(void*, int)' },
    GetAvgPackets = { 14, 'float(__thiscall*)(void*, int)' },
    GetTotalData = { 15, 'int(__thiscall*)(void*, int)' },
    GetTotalPackets = { 16, 'int(__thiscall*)(void*, int)' },
    GetSequenceNr = { 17, 'int(__thiscall*)(void*, int)' },
    IsValidPacket = { 18, 'bool(__thiscall*)(void*, int, int)' },
    GetPacketTime = { 19, 'float(__thiscall*)(void*, int, int)' },
    GetPacketBytes = { 20, 'int(__thiscall*)(void*, int, int, int)' },
    GetStreamProgress = { 21, 'bool(__thiscall*)(void*, int, int*, int*)' },
    GetTimeSinceLastReceived = { 22, 'float(__thiscall*)(void*)' },
    GetCommandInterpolationAmount = { 23, 'float(__thiscall*)(void*, int, int)' },
    GetPacketResponseLatency = { 24, 'void(__thiscall*)(void*, int, int, int*, int*)' },
    GetRemoteFramerate = { 25, 'void(__thiscall*)(void*, float*, float*, float*)' },
    GetTimeoutSeconds = { 26, 'float(__thiscall*)(void*)' }
});

local IEngineClient = memory:interface('engine', 'VEngineClient014', {
    GetNetChannel = { 78, 'void*(__thiscall*)(void*)' },
});

local net_channel_info_t = {}; do
    function net_channel_info_t:get_name()
        return ffi.string(self.this:GetName());
    end;

    function net_channel_info_t:get_address()
        return ffi.string(self.this:GetAddress());
    end;

    function net_channel_info_t:get_time()
        return self.this:GetTime();
    end;

    function net_channel_info_t:get_time_connected()
        return self.this:GetTimeConnected();
    end;

    function net_channel_info_t:get_buffer_size()
        return self.this:GetBufferSize();
    end;

    function net_channel_info_t:get_data_rate()
        return self.this:GetDataRate();
    end;

    function net_channel_info_t:is_loopback()
        return self.this:IsLoopback();
    end;

    function net_channel_info_t:is_timing_out()
        return self.this:IsTimingOut();
    end;

    function net_channel_info_t:is_playback()
        return self.this:IsPlayback();
    end;

    function net_channel_info_t:get_latency(flow)
        return self.this:GetLatency(flow);
    end;

    function net_channel_info_t:get_avg_latency(flow)
        return self.this:GetAvgLatency(flow);
    end;

    function net_channel_info_t:get_avg_loss(flow)
        return self.this:GetAvgLoss(flow);
    end;

    function net_channel_info_t:get_avg_choke(flow)
        return self.this:GetAvgChoke(flow);
    end;

    function net_channel_info_t:get_avg_data(flow)
        return self.this:GetAvgData(flow);
    end;

    function net_channel_info_t:get_avg_packets(flow)
        return self.this:GetAvgPackets(flow);
    end;

    function net_channel_info_t:get_total_data(flow)
        return self.this:GetTotalData(flow);
    end;

    function net_channel_info_t:get_total_packets(flow)
        return self.this:GetTotalPackets(flow);
    end;

    function net_channel_info_t:get_sequence_nr(flow)
        return self.this:GetSequenceNr(flow);
    end;

    function net_channel_info_t:is_valid_packet(flow, frame_number)
        return self.this:IsValidPacket(flow, frame_number);
    end;

    function net_channel_info_t:get_packet_time(flow, frame_number)
        return self.this:GetPacketTime(flow, frame_number);
    end;

    function net_channel_info_t:get_packet_bytes(flow, frame_number, group)
        return self.this:GetPacketBytes(flow, frame_number, group);
    end;

    function net_channel_info_t:get_stream_progress(flow)
        local received = ffi.new('int[1]');
        local total = ffi.new('int[1]');
        local success = self.this:GetStreamProgress(flow, received, total);
        return success, received[0], total[0];
    end;

    function net_channel_info_t:get_time_since_last_received()
        return self.this:GetTimeSinceLastReceived();
    end;

    function net_channel_info_t:get_command_interpolation_amount(flow, frame_number)
        return self.this:GetCommandInterpolationAmount(flow, frame_number);
    end;

    function net_channel_info_t:get_packet_response_latency(flow, frame_number)
        local latency_msecs = ffi.new('int[1]');
        local choke = ffi.new('int[1]');
        self.this:GetPacketResponseLatency(flow, frame_number, latency_msecs, choke);
        return latency_msecs[0], choke[0];
    end;

    function net_channel_info_t:get_remote_framerate()
        local frame_time = ffi.new('float[1]');
        local frame_time_std_deviation = ffi.new('float[1]');
        local frame_start_time_std_deviation = ffi.new('float[1]');
        self.this:GetRemoteFramerate(frame_time, frame_time_std_deviation, frame_start_time_std_deviation);
        return frame_time[0], frame_time_std_deviation[0], frame_start_time_std_deviation[0];
    end;

    function net_channel_info_t:get_timeout_seconds()
        return self.this:GetTimeoutSeconds();
    end;

    -- Set the metatable for instance method lookup
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
end;

return engine_client;
