local memory = require 'libs.memory';

---@class INetChannelInfo
---@field GetName fun(self: INetChannelInfo): string;
---@field GetAddress fun(self: INetChannelInfo): string;
---@field GetTime fun(self: INetChannelInfo): number;
---@field GetTimeConnected fun(self: INetChannelInfo): number;
---@field GetBufferSize fun(self: INetChannelInfo): number;
---@field GetDataRate fun(self: INetChannelInfo): number;
---@field IsLoopback fun(self: INetChannelInfo): boolean;
---@field IsTimingOut fun(self: INetChannelInfo): boolean;
---@field IsPlayback fun(self: INetChannelInfo): boolean;
---@field GetLatency fun(self: INetChannelInfo, flow: number): number;
---@field GetAvgLatency fun(self: INetChannelInfo, flow: number): number;
---@field GetAvgLoss fun(self: INetChannelInfo, flow: number): number;
---@field GetAvgChoke fun(self: INetChannelInfo, flow: number): number;
---@field GetAvgData fun(self: INetChannelInfo, flow: number): number;
---@field GetAvgPackets fun(self: INetChannelInfo, flow: number): number;
---@field GetTotalData fun(self: INetChannelInfo, flow: number): number;
---@field GetTotalPackets fun(self: INetChannelInfo, flow: number): number;
---@field GetSequenceNr fun(self: INetChannelInfo, flow: number): number;
---@field IsValidPacket fun(self: INetChannelInfo, flow: number, frame_number: number): boolean;
---@field GetPacketTime fun(self: INetChannelInfo, flow: number, frame_number: number): number;
---@field GetPacketBytes fun(self: INetChannelInfo, flow: number, frame_number: number, group: number): number;
---@field GetStreamProgress fun(self: INetChannelInfo, flow: number, received: ffi.cdata*, total: ffi.cdata*): boolean;
---@field GetTimeSinceLastReceived fun(self: INetChannelInfo): number;
---@field GetCommandInterpolationAmount fun(self: INetChannelInfo, flow: number, frame_number: number): number;
---@field GetPacketResponseLatency fun(self: INetChannelInfo, flow: number, frame_number: number, latency_msecs: ffi.cdata*, choke: ffi.cdata*);
---@field GetRemoteFramerate fun(self: INetChannelInfo, frame_time: ffi.cdata*, frame_time_std_deviation: ffi.cdata*, frame_start_time_std_deviation: ffi.cdata*);
---@field GetTimeoutSeconds fun(self: INetChannelInfo): number;
INetChannelInfo = memory:class({
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

---@class IMaterial
---@field GetName fun(self: IMaterial): ffi.cdata*
---@field GetTextureGroupName fun(self: IMaterial): ffi.cdata*
---@field AlphaModulate fun(self: IMaterial, alpha: number)
---@field ColorModulate fun(self: IMaterial, r: number, g: number, b: number)
---@field SetMaterialVarFlag fun(self: IMaterial, flag: number, state: boolean)
---@field GetMaterialVarFlag fun(self: IMaterial, flag: number): boolean
---@field IsErrorMaterial fun(self: IMaterial): boolean
IMaterial = memory:class({
    GetName = { 0, 'const char*(__thiscall*)(void*)' },
    GetTextureGroupName = { 1, 'const char*(__thiscall*)(void*)' },
    AlphaModulate = { 27, 'void(__thiscall*)(void*, float)' },
    ColorModulate = { 28, 'void(__thiscall*)(void*, float, float, float)' },
    SetMaterialVarFlag = { 29, 'void(__thiscall*)(void*, int, bool)' },
    GetMaterialVarFlag = { 30, 'bool(__thiscall*)(void*, int)' },
    IsErrorMaterial = { 42, 'bool(__thiscall*)(void*)' },
});

---@class IMaterialSystem
---@field CreateMaterial fun(self: IMaterialSystem, name: string, key_values: ffi.cdata*): ffi.cdata*
---@field FindMaterial fun(self: IMaterialSystem, name: string, texture_group_name?: string, complain?: boolean, complain_prefix?: string): ffi.cdata*
---@field FirstMaterial fun(self: IMaterialSystem): number
---@field NextMaterial fun(self: IMaterialSystem, handle: number): number
---@field InvalidMaterial fun(self: IMaterialSystem): number
---@field GetMaterial fun(self: IMaterialSystem, handle: number): ffi.cdata*
IMaterialSystem = memory:interface('materialsystem.dll', 'VMaterialSystem080', {
    CreateMaterial = { 83, 'void*(__thiscall*)(void*, char const*, void*)' },
    FindMaterial = { 84, 'void*(__thiscall*)(void*, char const*, const char*, bool, const char*)' },
    FirstMaterial = { 86, 'int(__thiscall*)(void*)' },
    NextMaterial = { 87, 'int(__thiscall*)(void*, int)' },
    InvalidMaterial = { 88, 'int(__thiscall*)(void*)' },
    GetMaterial = { 89, 'void*(__thiscall*)(void*, int)' },
});

---@class IClientEntityList
---@field GetClientEntity fun(self: IClientEntityList, index: number): number
---@field GetClientEntityFromHandle fun(self: IClientEntityList, handle: number): number
IClientEntityList = memory:interface('client.dll', 'VClientEntityList003', {
    GetClientEntity = { 3, 'uintptr_t(__thiscall*)(void*, int)' },
    GetClientEntityFromHandle = { 4, 'uintptr_t(__thiscall*)(void*, uintptr_t)' }
});

---@class IEngineSound
---@field EmitAmbientSound fun(self: IEngineSound, sound: string, volume: number, pitch: number, flags: number, delay: number): number
---@field StopSoundByGuid fun(self: IEngineSound, guid: number, play_end_sound: boolean)
IEngineSound = memory:interface('engine.dll', 'IEngineSoundClient003', {
    EmitAmbientSound = { 12, 'int(__thiscall*)(void*, const char*, float, int, int, float)' },
    StopSoundByGuid = { 17, 'void(__thiscall*)(void*, int, bool)' },
});

ISurface = memory:interface('vguimatsurface.dll', 'VGUI_Surface031', {
    SurfaceGetCursorPos = { 100, 'unsigned int(__thiscall*)(void *thisptr, int &x, int &y)' }
});

---@class IEngineClient
---@field GetLocalPlayer fun(self: IEngineClient): number
---@field GetNetChannel fun(self: IEngineClient): ffi.cdata*
IEngineClient = memory:interface('engine.dll', 'VEngineClient014', {
    GetLocalPlayer = { 12, 'int(__thiscall*)(void*)' },
    GetNetChannel = { 78, 'void*(__thiscall*)(void*)' },
});

---@class IVRenderView
---@field SetBlend fun(self: IVRenderView, value: number)
---@field GetBlend fun(self: IVRenderView): number
IVRenderView = memory:interface('engine.dll', 'VEngineRenderView014', {
    SetBlend = { 4, 'void(__thiscall*)(void*, float)' },
    GetBlend = { 5, 'float(__thiscall*)(void*)' },
});
