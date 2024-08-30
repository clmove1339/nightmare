_DEV = false;
NATIVE_PRINT = NATIVE_PRINT or print;
NotImplemented = 'NotImplemented';
unpack = unpack or table.unpack;
table.unpack = unpack;
screen = render.screen_size();

---@generic T
---@param a any
---@param b T
---@param c T
---@return T
function ternary(a, b, c)
    if a then
        return b;
    else
        return c;
    end;
end;

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

local ffi = ffi; do ---@cast ffi ffilib
    _G.ffi = ffi;

    ffi.cdef [[
        void* GetModuleHandleA(const char*);
        void* GetProcAddress(void*, const char*);
        int VirtualProtect(void*, unsigned long, unsigned long, unsigned long*);

        short GetKeyState(int);

        typedef struct {
            float x, y, z;
        } vector_t;

        typedef struct {
            char pad[8];
            float m_flStart;
            float m_flEnd;
            float m_flState;
        } pose_parameters_t;

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
            char pad_0090[52];
            int nWeaponID; // 0x00C4
	        int nWeaponType; // 0x00C8
	        char pad_0091[0x4]; // 0x00CC // @todo: int ammo related? in range 1 .. 5 @ida: "83 F9 10 77 2C"
	        int iWeaponPrice; // 0x00D0 // "in game price"
	        int iKillAward; // 0x00D4 // "kill award"
	        const char* szAnimationExtension; // 0x00D8 // @xref: "player_animation_extension"
	        float flCycleTime; // 0x00DC // "cycletime"
	        float flCycleTimeAlt; // 0x00E0 // "cycletime alt"
	        float flTimeToIdleAfterFire; // 0x00E4 // "time to idle"
	        float flIdleInterval; // 0x00E8 // "idle interval"
	        bool bFullAuto; // 0x00EC // "is full auto"
	        int iDamage; // 0x00F0 // "damage"
	        float flHeadShotMultiplier; // 0x00F4 // "headshot multiplier"
	        float flArmorRatio; // 0x00F8 // "armor ratio"
	        int iBullets; // 0x00FC // "bullets"
	        float flPenetration; // 0x0100 // "penetration"
	        float flFlinchVelocityModifierLarge; // 0x0104 // "flinch velocity modifier large"
	        float flFlinchVelocityModifierSmall; // 0x0108 // "flinch velocity modifier small"
	        float flRange; // 0x010C // "range"
	        float flRangeModifier; // 0x0110 // "range modifier"
	        float flThrowVelocity; // 0x0114 // "throw velocity"
	        vector_t vecSmokeColor; // 0x0118 // @xref: "grenade_smoke_color"
	        bool bHasSilencer; // 0x0124 // "has silencer"
	        const char* szSilencerModel; // 0x0128 // "silencer model"
	        int iCrosshairMinDistance; // 0x012C // "crosshair min distance"
	        int iCrosshairDeltaDistance; // 0x0130 // "crosshair delta distance"
	        float flMaxSpeed[2]; // 0x0134 // "max player speed", "max player speed alt"
	        float flAttackMoveSpeedFactor; // 0x013C "attack movespeed factor"
	        float flSpread[2]; // 0x0140 // "spread", "spread alt"
	        float flInaccuracyCrouch[2]; // 0x0148 // "inaccuracy crouch", "inaccuracy crouch alt"
	        float flInaccuracyStand[2]; // 0x0150 // "inaccuracy stand", "inaccuracy stand alt"
	        float flInaccuracyJumpInitial; // 0x0158 // "inaccuracy jump initial"
	        float flInaccuracyJumpApex; // 0x015C // "inaccuracy jump apex"
	        float flInaccuracyJump[2]; // 0x0160 // "inaccuracy jump", "inaccuracy jump alt"
	        float flInaccuracyLand[2]; // 0x0168 // "inaccuracy land", "inaccuracy land alt"
	        float flInaccuracyLadder[2]; // 0x0170 // "inaccuracy ladder", "inaccuracy ladder alt"
	        float flInaccuracyFire[2]; // 0x0178 // "inaccuracy fire", "inaccuracy fire alt"
	        float flInaccuracyMove[2]; // 0x0180 // "inaccuracy move", "inaccuracy move alt"
	        float flInaccuracyReload; // 0x0188 // "inaccuracy reload"
	        int nRecoilSeed; // 0x018C // "recoil seed"
	        float flRecoilAngle[2]; // 0x0190 // "recoil angle", "recoil angle alt"
	        float flRecoilAngleVariance[2]; // 0x0198 // "recoil angle variance", "recoil angle variance alt"
	        float flRecoilMagnitude[2]; // 0x01A0 // "recoil magnitude", "recoil magnitude alt"
	        float flRecoilMagnitudeVariance[2]; // 0x01A8 // "recoil magnitude variance", "recoil magnitude variance alt"
	        int nSpreadSeed; // 0x01B0 // "spread seed"
	        float flRecoveryTimeCrouch; // 0x01B4 // "recovery time crouch"
	        float flRecoveryTimeStand; // 0x01B8 // "recovery time stand"
	        float flRecoveryTimeCrouchFinal; // 0x01BC // "recovery time crouch final"
	        float flRecoveryTimeStandFinal; // 0x01C0 // "recovery time stand final"
	        int iRecoveryTransitionStartBullet; // 0x01C4 // "recovery transition start bullet"
	        int iRecoveryTransitionEndBullet; // 0x01C8 // "recovery transition end bullet"
	        bool bUnzoomAfterShot;// 0x01CC // "unzoom after shot"
	        bool bHideViewModelZoomed; // 0x01CD // "hide view model zoomed"
	        int iZoomLevels; // 0x01D0 // "zoom levels"
	        int iZoomFOV[2]; // 0x01D4 // "zoom fov 1", "zoom time 2"
	        float flZoomTime[3]; // 0x01DC // "zoom time 0", "zoom time 1", "zoom time 2"
	        const char* szAddonLocation; // 0x01E8 // @xref: "addon location"
	        float flAddonScale; // 0x01EC // "addon scale"
	        char pad5[0x8]; // 0x01F0 // @todo: shell casing rel
	        const char* szTracerEffectName; // 0x01F8 // @xref: "tracer_effect"
	        int iTracerFrequency; // 0x01FC // "tracer frequency"
	        int iTracerFrequencyAlt; // 0x0200 // "tracer frequency alt"
	        const char* szMuzzleFlashEffectName1stPerson; // 0x0204 // @xref: "muzzle_flash_effect_1st_person"
	        const char* szMuzzleFlashEffectName1stPersonAlt; // 0x0208 // @xref: "muzzle_flash_effect_1st_person_alt"
	        const char* szMuzzleFlashEffectName3rdPerson; // 0x020C // @xref: "muzzle_flash_effect_3rd_person"
	        const char* szMuzzleFlashEffectName3rdPersonAlt; // 0x0210 // @xref: "muzzle_flash_effect_3rd_person_alt"
	        const char* szHeatEffectName; // 0x0214 // @xref: "heat_effect"
	        float flHeatPerShot; // 0x0218 // "heat per shot"
	        const char* szZoomInSound; // 0x021C
	        const char* szZoomOutSound; // 0x0220
	        float flInaccuracyPitchShift; // 0x0224 // "inaccuracy pitch shift"
	        float flInaccuracyAltSoundThreshold; // 0x0228 // "inaccuracy alt sound threshold"
	        float flBotAudibleRange; // 0x022C // "bot audible range"
	        char pad6[0x8]; // 0x0230
	        const char* szWrongTeamMsg; // 0x0238 // "wrong team msg"
	        bool bHasBurstMode; // 0x023C // "has burst mode"
	        bool bIsRevolver; // 0x023D // "is revolver"
	        bool bCannotShootUnderwater; // 0x023E // "cannot shoot underwater"
        } weapon_info_t;

        typedef struct {
            int id;
            int version;
            int checksum;
            char name[64];
            int length;
            vector_t eyePosition;
            vector_t illumPosition;
            vector_t hullMin;
            vector_t hullMax;
            vector_t bbMin;
            vector_t bbMax;
            int flags;
            int numBones;
            int boneIndex;
            int numBoneControllers;
            int boneControllerIndex;
            int numHitboxSets;
            int hitboxSetIndex;
        } StudioHdr;

        typedef struct {
            int nameIndex;
            int numHitboxes;
            int hitboxIndex;
        } StudioHitboxSet;

        typedef struct {
            int bone;
            int group;
            vector_t bbMin;
            vector_t bbMax;
            int hitboxNameIndex;
            vector_t offsetOrientation;
            float capsuleRadius;
            int unused[4];
        } StudioBbox;

        typedef struct {
            int64_t __pad0;
            union {
                int64_t xuid;
                struct {
                    int xuidlow;
                    int xuidhigh;
                };
            };
            char name[128];
            int userid;
            char guid[33];
            unsigned int friends_id;
            char friends_name[128];
            bool fake_player;
            bool is_hltv;
            unsigned int custom_files[4];
            unsigned char files_downloaded;
        } player_info_t;
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

---@param x number
---@param min number
---@param max number
---@return number
function normalize(x, min, max)
    if x < min or x > max then
        local delta = max - min;
        local offset = x - min;

        return min + (offset % delta);
    end;

    return x;
end;

---@param x number
---@return number
function normalize_yaw(x)
    return normalize(x, -180, 180);
end;

function has_bit(x, p)
    return x % (p + p) >= p;
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
