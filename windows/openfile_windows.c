#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Function to check if QuickLook for Windows is installed
BOOL isQuickLookInstalled() {
    wchar_t quickLookPath[MAX_PATH];
    
    // Check common installation paths (user-local first, then system-wide)
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

// Function to launch QuickLook.exe if not already running
BOOL ensureQuickLookRunning(const wchar_t* quickLookPath) {
    // Check if QuickLook is already running
    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnapshot == INVALID_HANDLE_VALUE) {
        return FALSE;
    }
    
    PROCESSENTRY32W pe32;
    pe32.dwSize = sizeof(PROCESSENTRY32W);
    
    BOOL isRunning = FALSE;
    if (Process32FirstW(hSnapshot, &pe32)) {
        do {
            if (wcscmp(pe32.szExeFile, L"QuickLook.exe") == 0) {
                isRunning = TRUE;
                break;
            }
        } while (Process32NextW(hSnapshot, &pe32));
    }
    CloseHandle(hSnapshot);
    
    if (!isRunning) {
        wchar_t commandLine[MAX_PATH * 2];
        swprintf_s(commandLine, MAX_PATH * 2, L"\"%s\"", quickLookPath);
        
        STARTUPINFOW si = {0};
        PROCESS_INFORMATION pi = {0};
        si.cb = sizeof(si);
        
        if (CreateProcessW(NULL, commandLine, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            // Give QuickLook time to initialize
            Sleep(1000);
            return TRUE;
        }
    }
    
    return isRunning;
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

// Windows implementation of the openFiles function
int openFiles(int argc, const char **argv, int fullscreen) {
    if (argc <= 0 || argv == NULL) {
        printf("Error: No files provided to open.\n");
        return 1;
    }

    printf("Opening %d file(s) with QuickLook...\n", argc);
    
    // Check if QuickLook is installed
    BOOL hasQuickLook = isQuickLookInstalled();
    if (!hasQuickLook) {
        printf("QuickLook for Windows not found. Please install it from https://github.com/QL-Win/QuickLook\n");
        return 1;
    }
    
    for (int i = 0; i < argc; i++) {
        const char* filePath = argv[i];
        printf("Processing file: %s\n", filePath);

        // Convert to wide string for Windows API
        int len = MultiByteToWideChar(CP_UTF8, 0, filePath, -1, NULL, 0);
        if (len == 0) {
            printf("Error: Failed to convert file path to wide string: %s\n", filePath);
            continue;
        }

        wchar_t* wideFilePath = (wchar_t*)malloc(len * sizeof(wchar_t));
        if (!wideFilePath) {
            printf("Error: Memory allocation failed for file: %s\n", filePath);
            continue;
        }

        if (MultiByteToWideChar(CP_UTF8, 0, filePath, -1, wideFilePath, len) == 0) {
            printf("Error: Failed to convert file path: %s\n", filePath);
            free(wideFilePath);
            continue;
        }

        // Check if file exists
        DWORD fileAttr = GetFileAttributesW(wideFilePath);
        if (fileAttr == INVALID_FILE_ATTRIBUTES) {
            printf("Error: File not found or inaccessible: %s\n", filePath);
            free(wideFilePath);
            continue;
        }

        // Try to preview with QuickLook
        if (!previewWithQuickLook(wideFilePath)) {
            printf("Failed to preview file with QuickLook: %s\n", filePath);
            free(wideFilePath);
            continue;
        }

        free(wideFilePath);
        printf("Successfully previewed: %s\n", filePath);
    }
    
    return 0;
}

#endif // _WIN32