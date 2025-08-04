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
        wchar_t expandedPath[MAX_PATH];
        if (ExpandEnvironmentStringsW(locations[i], expandedPath, MAX_PATH)) {
            if (GetFileAttributesW(expandedPath) != INVALID_FILE_ATTRIBUTES) {
                wcscpy_s(path, MAX_PATH, expandedPath);
                return TRUE;
            }
        }
    }
    return FALSE;
}

// Direct QuickLook invocation as per official documentation
// Function prototype for path checker
static BOOL getQuickLookPath(wchar_t* path);

BOOL launchQuickLook(const wchar_t* filePath, BOOL fullscreen) {
    if (!filePath) return FALSE;

    wchar_t qlPath[MAX_PATH];
    if (!getQuickLookPath(qlPath)) {
        fprintf(stderr, "Error: QuickLook.exe not found in expected locations\n");
        return FALSE;
    }

    wchar_t cmdLine[MAX_PATH * 3];
    if (swprintf_s(cmdLine, MAX_PATH * 3, 
        L"\"%s\" /preview:\"%s\"%s", 
        qlPath, filePath, 
        fullscreen ? L" /fullscreen" : L"") < 0) {
        fprintf(stderr, "Error: Command line too long\n");
        return FALSE;
    }

    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    
    if (!CreateProcessW(NULL, cmdLine, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        DWORD error = GetLastError();
        fprintf(stderr, "Error launching QuickLook: %lu\n", error);
        return FALSE;
    }

    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return TRUE;
}

// Simplified Windows file opener
int openFiles(int argc, const char **argv, int fullscreen) {
    if (argc < 1 || !argv) {
        fprintf(stderr, "Error: No file paths provided\n");
        return 1;
    }

    BOOL anySuccess = FALSE;
    for (int i = 0; i < argc; i++) {
        const char* utf8Path = argv[i];
        if (!utf8Path) {
            fprintf(stderr, "Error: Invalid path argument at position %d\n", i);
            continue;
        }

        int wideLen = MultiByteToWideChar(CP_UTF8, 0, utf8Path, -1, NULL, 0);
        if (wideLen == 0) {
            fprintf(stderr, "Error: Failed to convert path to wide string: %s\n", utf8Path);
            continue;
        }

        wchar_t* widePath = (wchar_t*)malloc(wideLen * sizeof(wchar_t));
        if (!widePath) {
            fprintf(stderr, "Error: Memory allocation failed for path: %s\n", utf8Path);
            continue;
        }

        if (!MultiByteToWideChar(CP_UTF8, 0, utf8Path, -1, widePath, wideLen)) {
            fprintf(stderr, "Error: Path conversion failed: %s\n", utf8Path);
            free(widePath);
            continue;
        }

        if (GetFileAttributesW(widePath) == INVALID_FILE_ATTRIBUTES) {
            fprintf(stderr, "Error: File not found or inaccessible: %s\n", utf8Path);
            free(widePath);
            continue;
        }

        if (launchQuickLook(widePath, fullscreen)) {
            anySuccess = TRUE;
        }
        free(widePath);
    }

    return anySuccess ? 0 : 1;
}

#endif // _WIN32