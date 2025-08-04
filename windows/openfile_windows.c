#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Simplified path check for QuickLook.exe
static BOOL getQuickLookPath(wchar_t* path) {
    const wchar_t* locations[] = {
        L"%LOCALAPPDATA%\\Programs\\QuickLook\\QuickLook.exe",
        L"%PROGRAMFILES%\\QuickLook\\QuickLook.exe",
        L"%PROGRAMFILES(X86)%\\QuickLook\\QuickLook.exe"
    };

    for (int i = 0; i < sizeof(locations)/sizeof(locations[0]); i++) {
        if (ExpandEnvironmentStringsW(locations[i], path, MAX_PATH) 
            && GetFileAttributesW(path) != INVALID_FILE_ATTRIBUTES) {
            return TRUE;
        }
    }
    return FALSE;
}

// Direct QuickLook invocation as per official documentation
BOOL launchQuickLook(const wchar_t* filePath, BOOL fullscreen) {
    wchar_t qlPath[MAX_PATH];
    if (!getQuickLookPath(qlPath)) return FALSE;

    wchar_t cmdLine[MAX_PATH * 3];
    swprintf_s(cmdLine, MAX_PATH * 3, 
        L"\"%s\" /standby /preview:\"%s\"%s", 
        qlPath, filePath, 
        fullscreen ? L" /fullscreen" : L"");

    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    
    if (CreateProcessW(NULL, cmdLine, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return TRUE;
    }
    return FALSE;
}

// Function to get the path to QuickLook.exe
BOOL getQuickLookPath(wchar_t* quickLookPath) {
    const wchar_t* paths[] = {
        L"%LOCALAPPDATA%\\Programs\\QuickLook\\QuickLook.exe",
        L"%PROGRAMFILES%\\QuickLook\\QuickLook.exe",
        L"%PROGRAMFILES(X86)%\\QuickLook\\QuickLook.exe"
    };
    
    for (int i = 0; i < sizeof(paths)/sizeof(paths[0]); i++) {
        if (ExpandEnvironmentStringsW(paths[i], quickLookPath, MAX_PATH)) {
            DWORD fileAttr = GetFileAttributesW(quickLookPath);
            if (fileAttr != INVALID_FILE_ATTRIBUTES && !(fileAttr & FILE_ATTRIBUTE_DIRECTORY)) {
                return TRUE;
            }
        }
    }
    
    return FALSE;
}

// Function to preview files with QuickLook
BOOL previewWithQuickLook(const wchar_t* filePath) {
    wchar_t quickLookPath[MAX_PATH];
    if (!getQuickLookPath(quickLookPath)) {
        return FALSE;
    }
    
    if (!ensureQuickLookRunning(quickLookPath)) {
        return FALSE;
    }
    
    // Build command line to tell QuickLook to preview the file
    wchar_t commandLine[MAX_PATH * 2];
    swprintf_s(commandLine, MAX_PATH * 2, L"\"%s\" /standby /preview: \"%s\"", quickLookPath, filePath);
    
    STARTUPINFOW si = {0};
    PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si);
    
    if (CreateProcessW(NULL, commandLine, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return TRUE;
    }
    
    return FALSE;
}

// Simplified Windows file opener
int openFiles(int argc, const char **argv, int fullscreen) {
    if (argc < 1 || !argv) return 1;

    for (int i = 0; i < argc; i++) {
        const char* utf8Path = argv[i];
        int wideLen = MultiByteToWideChar(CP_UTF8, 0, utf8Path, -1, NULL, 0);
        if (wideLen == 0) continue;

        wchar_t* widePath = (wchar_t*)malloc(wideLen * sizeof(wchar_t));
        if (!widePath || !MultiByteToWideChar(CP_UTF8, 0, utf8Path, -1, widePath, wideLen)
            || GetFileAttributesW(widePath) == INVALID_FILE_ATTRIBUTES) {
            free(widePath);
            continue;
        }

        launchQuickLook(widePath, fullscreen);
        free(widePath);
    }
    return 0;
}

#endif // _WIN32