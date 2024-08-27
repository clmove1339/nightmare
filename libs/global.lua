_DEV = false;
NATIVE_PRINT = NATIVE_PRINT or print;
NotImplemented = 'NotImplemented';
unpack = unpack or table.unpack;
table.unpack = unpack;
screen = render.screen_size();

---Checks if a flag is set in a set of flags
---@param flags integer The set of flags
---@param flag integer The flag to check
---@return boolean `true` if the flag is set, otherwise `false`
bit.has = function(flags, flag)
    return bit.band(flags, flag) == flag;
end;

---Checks if a flag is not set in a set of flags
---@param flags integer The set of flags
---@param flag integer The flag to check
---@return boolean `true` if the flag is not set, otherwise `false`
bit.hasnt = function(flags, flag)
    return bit.band(flags, flag) == 0;
end;

---@param v any
---@return type
function typeof(v)
    local vtype = type(v);

    if (vtype == 'table' or vtype == 'userdata') then
        local meta = getmetatable(v);
        if not meta then
            return 'table';
        end;

        local meta_type = meta.__type;

        if meta_type then
            if meta_type.name then
                return meta_type.name;
            else
                return meta_type;
            end;
        end;

        return 'table';
    end;

    return vtype;
end;

ffi = require 'ffi'; do
    ffi.cdef [[
        void* GetModuleHandleA(const char*);
        void* GetProcAddress(void*, const char*);
        int VirtualProtect(void*, unsigned long, unsigned long, unsigned long*);

        typedef struct {
            char pad_0000[4];
            char* ConsoleName;
            char pad_0008[12];
            int iMaxClip1;
            char pad_0018[12];
            int iMaxClip2;
            char pad_0028[4];
            char* szWorldModel;
            char* szViewModel;
            char* szDropedModel;
            char pad_0038[4];
            char* N00000984;
            char pad_0040[56];
            char* szEmptySound;
            char pad_007C[4];
            char* szBulletType;
            char pad_0084[4];
            char* szHudName;
            char* szWeaponName;
            char pad_0090[60];
            int WeaponType;
            int iWeaponPrice;
            int iKillAward;
            char* szAnimationPrefex;
            float flCycleTime;
            float flCycleTimeAlt;
            float flTimeToIdle;
            float flIdleInterval;
            bool bFullAuto;
            char pad_00ED[3];
            int iDamage;
            float flArmorRatio;
            int iBullets;
            float flPenetration;
            float flFlinchVelocityModifierLarge;
            float flFlinchVelocityModifierSmall;
            float flRange;
            float flRangeModifier;
            float flThrowVelocity;
            char pad_0110[24];
            int iCrosshairMinDistance;
            float flMaxPlayerSpeed;
            float flMaxPlayerSpeedAlt;
            char pad_0138[4];
            float flSpread;
            float flSpreadAlt;
            float flInaccuracyCrouch;
            float flInaccuracyCrouchAlt;
            float flInaccuracyStand;
            float flInaccuracyStandAlt;
            float flInaccuracyJumpIntial;
            float flInaccaurcyJumpApex;
            float flInaccuracyJump;
            float flInaccuracyJumpAlt;
            float flInaccuracyLand;
            float flInaccuracyLandAlt;
            float flInaccuracyLadder;
            float flInaccuracyLadderAlt;
            float flInaccuracyFire;
            float flInaccuracyFireAlt;
            float flInaccuracyMove;
            float flInaccuracyMoveAlt;
            float flInaccuracyReload;
            int iRecoilSeed;
            float flRecoilAngle;
            float flRecoilAngleAlt;
            float flRecoilVariance;
            float flRecoilAngleVarianceAlt;
            float flRecoilMagnitude;
            float flRecoilMagnitudeAlt;
            float flRecoilMagnatiudeVeriance;
            float flRecoilMagnatiudeVerianceAlt;
            float flRecoveryTimeCrouch;
            float flRecoveryTimeStand;
            float flRecoveryTimeCrouchFinal;
            float flRecoveryTimeStandFinal;
            int iRecoveryTransititionStartBullet;
            int iRecoveryTransititionEndBullet;
            bool bUnzoomAfterShot;
            char pad_01C1[31];
            char* szWeaponClass;
            char pad_01E4[56];
            float flInaccuracyPitchShift;
            float flInaccuracySoundThreshold;
        } weapon_info_t;
    ]];
end;

---Enhanced print function
---@param ... any
function print(...)
    local args = { ... };
    for i = 1, #args do
        local arg = args[i];
        NATIVE_PRINT(tostring(arg));
    end;
end;

---Print formatted string
---@param ... any
function printf(...)
    print(string.format(...));
end;

---Prints the contents of a table, including nested tables, in a readable format.
---@param list table The table to print.
---@param indent string|nil Used for formatting nested tables (internal use).
function print_t(list, indent)
    indent = indent or '';

    for key, value in pairs(list) do
        if type(value) == 'table' then
            print(indent .. tostring(key) .. ':');
            print_t(value, indent .. '    ');
        else
            print(indent .. tostring(key) .. ': ' .. tostring(value));
        end;
    end;
end;

---Clamp a number between mn and mx
---@param x number
---@param mn number
---@param mx number
---@return number
math.clamp = function(x, mn, mx)
    return x <= mn and mn or (x >= mx and mx or x);
end;

---Linear interpolation between a and b with t
---@param a number
---@param b number
---@param t number
---@return number
math.lerp = function(a, b, t)
    return a + (b - a) * t;
end;

---Initialize random seed
math.randomize = function()
    math.randomseed(os.time());
end;

---Check if a number is within a specific range
---@param x number
---@param mn number
---@param mx number
---@return boolean
function math.inrange(x, mn, mx)
    return x >= mn and x <= mx;
end;

---Round a number to the nearest integer or to a specific number of decimal places
---@param num number
---@param idp integer|nil @decimal places (optional)
---@return number
function math.round(num, idp)
    local mult = 10 ^ (idp or 0);
    return math.floor(num * mult + 0.5) / mult;
end;

---Measures the average time taken to execute a function.
---The `iterations` parameter increases the execution time, allowing for more stable measurements.
---The `accuracy` parameter increases the precision of the result by running the benchmark multiple times and averaging the results.
---@param fn function The function to benchmark.
---@param iterations? integer The number of times the function should be executed within a single benchmark run.
---@param accuracy? integer The number of times the benchmark should be repeated to improve accuracy. Defaults to 5 if not provided.
---@param ... any Additional arguments to pass to the benchmarked function.
---@return number time The average time taken for the function to execute.
function benchmark(fn, iterations, accuracy, ...)
    local avg = 0;
    local accuracy = accuracy or 5;
    local iterations = iterations or 10;
    local args = { ... };

    for _ = 1, accuracy do
        local start_time = os.clock();
        if #args ~= 0 then
            for i = 1, iterations do
                fn(..., i);
            end;
        else
            for i = 1, iterations do
                fn(i);
            end;
        end;
        local end_time = os.clock();
        avg = avg + end_time - start_time;
    end;

    return avg / accuracy;
end;
