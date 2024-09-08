ffi.cdef [[
    typedef int BOOL;
    typedef unsigned long DWORD;
    typedef const char* LPCSTR;
    typedef void* HANDLE;
    typedef unsigned int UINT;

    typedef struct {
        DWORD dwSize;
        DWORD cntUsage;
        DWORD th32ProcessID;
        DWORD th32DefaultHeapID;
        DWORD th32ModuleID;
        DWORD cntThreads;
        DWORD th32ParentProcessID;
        long  pcPriClassBase;
        DWORD dwFlags;
        char  szExeFile[260];
    } PROCESSENTRY32;

    DWORD CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
    BOOL Process32First(DWORD hSnapshot, PROCESSENTRY32 *lppe);
    BOOL Process32Next(DWORD hSnapshot, PROCESSENTRY32 *lppe);
    BOOL CloseHandle(DWORD hObject);

    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
    BOOL TerminateProcess(HANDLE hProcess, UINT uExitCode);

    enum {
        TH32CS_SNAPPROCESS = 0x00000002,
        PROCESS_TERMINATE = 0x0001
    };
]];

local INVALID_HANDLE_VALUE = ffi.cast('DWORD', -1);

local winapi = {}; do
    ---@param name string
    ---@return number? result, string? msg
    winapi.get_process_id = function(name)
        local snapshot = ffi.C.CreateToolhelp32Snapshot(ffi.C.TH32CS_SNAPPROCESS, 0);
        if snapshot == INVALID_HANDLE_VALUE then
            return nil, 'Failed to create snapshot';
        end;

        local entry = ffi.new('PROCESSENTRY32');
        entry.dwSize = ffi.sizeof(entry);

        if ffi.C.Process32First(snapshot, entry) == 0 then
            ffi.C.CloseHandle(snapshot);
            return nil, 'Failed to retrieve process list';
        end;

        repeat
            if ffi.string(entry.szExeFile) == name then
                ffi.C.CloseHandle(snapshot);
                return tonumber(entry.th32ProcessID);
            end;
        until ffi.C.Process32Next(snapshot, entry) == 0;

        ffi.C.CloseHandle(snapshot);
        return nil, 'Process not found';
    end;

    ---@param name string
    ---@return boolean? result, string msg
    winapi.terminate_process = function(name)
        local snapshot = ffi.C.CreateToolhelp32Snapshot(ffi.C.TH32CS_SNAPPROCESS, 0);
        if snapshot == INVALID_HANDLE_VALUE then
            return nil, 'Failed to create snapshot';
        end;

        local entry = ffi.new('PROCESSENTRY32');
        entry.dwSize = ffi.sizeof(entry);

        if ffi.C.Process32First(snapshot, entry) == 0 then
            ffi.C.CloseHandle(snapshot);
            return nil, 'Failed to retrieve process list';
        end;

        repeat
            if ffi.string(entry.szExeFile) == name then
                local pid = entry.th32ProcessID;
                local process_handle = ffi.C.OpenProcess(ffi.C.PROCESS_TERMINATE, false, pid);
                if process_handle ~= nil then
                    ffi.C.TerminateProcess(process_handle, 0);
                    ffi.C.CloseHandle(process_handle);
                    ffi.C.CloseHandle(snapshot);
                    return true, 'Process terminated';
                end;
            end;
        until ffi.C.Process32Next(snapshot, entry) == 0;

        ffi.C.CloseHandle(snapshot);
        return nil, 'Process not found';
    end;
end;

return winapi;
