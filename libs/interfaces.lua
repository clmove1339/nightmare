local memory = require 'libs.memory';

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

IMaterialSystem = memory:interface('materialsystem.dll', 'VMaterialSystem080', {
    CreateMaterial = { 83, 'void*(__thiscall*)(void*, char const*, void*)' },
    FindMaterial = { 84, 'void*(__thiscall*)(void*, char const*, const char*, bool, const char*)' },
    FirstMaterial = { 86, 'int(__thiscall*)(void*)' },
    NextMaterial = { 87, 'int(__thiscall*)(void*, int)' },
    InvalidMaterial = { 88, 'int(__thiscall*)(void*)' },
    GetMaterial = { 89, 'void*(__thiscall*)(void*, int)' },
});

IClientEntityList = memory:interface('client', 'VClientEntityList003', {
    GetClientEntity = { 3, 'uintptr_t(__thiscall*)(void*, int)' },
    GetClientEntityFromHandle = { 4, 'uintptr_t(__thiscall*)(void*, uintptr_t)' }
});
