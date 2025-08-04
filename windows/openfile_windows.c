#ifdef _WIN32
#include "../openfile.h"
#include <windows.h>
#include <shellapi.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Function to check if QuickLook for Windows is installed
BOOL isQuickLookInstalled() {
    // Check common installation paths for QuickLook
    wchar_t quickLookPath[MAX_PATH];
    
    // Try user-specific installation path first
    if (ExpandEnvironmentStringsW(L"%LOCALAPPDATA%\\Programs\\QuickLook\\QuickLook.exe", quickLookPath, MAX_PATH)) {
        DWORD fileAttr = GetFileAttributesW(quickLookPath);
        if (fileAttr != INVALID_FILE_ATTRIBUTES && !(fileAttr & FILE_ATTRIBUTE_DIRECTORY)) {
            return TRUE;
        }
    }
    
    // Try system-wide installation path
    if (ExpandEnvironmentStringsW(L"%PROGRAMFILES%\\QuickLook\\QuickLook.exe", quickLookPath, MAX_PATH)) {
        DWORD fileAttr = GetFileAttributesW(quickLookPath);
        if (fileAttr != INVALID_FILE_ATTRIBUTES && !(fileAttr & FILE_ATTRIBUTE_DIRECTORY)) {
            return TRUE;
        }
    }
    
    // Try Program Files (x86)
    if (ExpandEnvironmentStringsW(L"%PROGRAMFILES(X86)%\\QuickLook\\QuickLook.exe", quickLookPath, MAX_PATH)) {
        DWORD fileAttr = GetFileAttributesW(quickLookPath);
        if (fileAttr != INVALID_FILE_ATTRIBUTES && !(fileAttr & FILE_ATTRIBUTE_DIRECTORY)) {
            return TRUE;
        }
    }
    
    return FALSE;
}

// Function to launch QuickLook for Windows
BOOL launchQuickLook(const wchar_t* filePath) {
    wchar_t quickLookPath[MAX_PATH];
    wchar_t commandLine[MAX_PATH * 2];
    
    // Try to find QuickLook.exe in common installation paths
    BOOL found = FALSE;
    
    // Try user-specific installation path first
    if (ExpandEnvironmentStringsW(L"%LOCALAPPDATA%\\Programs\\QuickLook\\QuickLook.exe", quickLookPath, MAX_PATH)) {
        DWORD fileAttr = GetFileAttributesW(quickLookPath);
        if (fileAttr != INVALID_FILE_ATTRIBUTES && !(fileAttr & FILE_ATTRIBUTE_DIRECTORY)) {
            found = TRUE;
        }
    }
    
    // Try system-wide installation path
    if (!found && ExpandEnvironmentStringsW(L"%PROGRAMFILES%\\QuickLook\\QuickLook.exe", quickLookPath, MAX_PATH)) {
        DWORD fileAttr = GetFileAttributesW(quickLookPath);
        if (fileAttr != INVALID_FILE_ATTRIBUTES && !(fileAttr & FILE_ATTRIBUTE_DIRECTORY)) {
            found = TRUE;
        }
    }
    
    // Try Program Files (x86)
    if (!found && ExpandEnvironmentStringsW(L"%PROGRAMFILES(X86)%\\QuickLook\\QuickLook.exe", quickLookPath, MAX_PATH)) {
        DWORD fileAttr = GetFileAttributesW(quickLookPath);
        if (fileAttr != INVALID_FILE_ATTRIBUTES && !(fileAttr & FILE_ATTRIBUTE_DIRECTORY)) {
            found = TRUE;
        }
    }
    
    if (!found) {
        return FALSE;
    }
    
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
        // Launch QuickLook.exe without arguments
        swprintf_s(commandLine, MAX_PATH * 2, L"\"%s\"", quickLookPath);
        
        STARTUPINFOW si = {0};
        PROCESS_INFORMATION pi = {0};
        si.cb = sizeof(si);
        
        if (CreateProcessW(NULL, commandLine, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            Sleep(2000); // Wait 2 seconds for it to start
        }
    }
    
    // Now launch with the file path to preview
    swprintf_s(commandLine, MAX_PATH * 2, L"\"%s\" \"%s\"", quickLookPath, filePath);
    
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

// Simple message handler for preview window
LRESULT CALLBACK PreviewWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_KEYDOWN:
            if (wParam == VK_ESCAPE || wParam == VK_SPACE) {
                DestroyWindow(hwnd);
                return 0;
            }
            break;
        case WM_CLOSE:
            DestroyWindow(hwnd);
            return 0;
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            
            // Simple text display
            RECT rect;
            GetClientRect(hwnd, &rect);
            DrawTextW(hdc, L"File Preview\n\nPress ESC or SPACE to close", -1, &rect, 
                     DT_CENTER | DT_VCENTER | DT_WORDBREAK);
            
            EndPaint(hwnd, &ps);
            return 0;
        }
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

// Function to show a basic preview window
BOOL showPreviewWindow(const wchar_t* filePath, BOOL fullscreen) {
    // Register window class
    WNDCLASSW wc = {0};
    wc.lpfnWndProc = PreviewWindowProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = L"QuickPreviewWindow";
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    
    RegisterClassW(&wc); // Ignore if already registered
    
    // Calculate window size and position
    DWORD style = fullscreen ? WS_POPUP : (WS_OVERLAPPEDWINDOW & ~WS_MAXIMIZEBOX);
    int width = fullscreen ? GetSystemMetrics(SM_CXSCREEN) : 800;
    int height = fullscreen ? GetSystemMetrics(SM_CYSCREEN) : 600;
    int x = fullscreen ? 0 : (GetSystemMetrics(SM_CXSCREEN) - width) / 2;
    int y = fullscreen ? 0 : (GetSystemMetrics(SM_CYSCREEN) - height) / 2;
    
    // Create window
    HWND hwnd = CreateWindowW(L"QuickPreviewWindow", L"Quick Preview", style,
        x, y, width, height, NULL, NULL, GetModuleHandle(NULL), NULL);
    
    if (!hwnd) {
        return FALSE;
    }
    
    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);
    
    printf("Preview window opened. Press ESC or SPACE to close, or close the window.\n");
    
    // Simple message loop
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    
    return TRUE;
}

// Windows implementation of the openFiles function
int openFiles(int argc, const char **argv, int fullscreen) {
    if (argc <= 0 || argv == NULL) {
        printf("Error: No files provided to open.\n");
        return 1;
    }

    printf("Opening %d file(s) with Windows QuickLook equivalent...\n", argc);
    
    // Check if QuickLook is installed
    BOOL hasQuickLook = isQuickLookInstalled();
    
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

        BOOL success = FALSE;
        
        // Try QuickLook for Windows first if available
        if (hasQuickLook) {
            printf("Attempting to use QuickLook for Windows...\n");
            success = launchQuickLook(wideFilePath);
        }
        
        // If QuickLook is not available or failed, use our preview window
        if (!success) {
            printf("Using built-in preview window...\n");
            success = showPreviewWindow(wideFilePath, fullscreen);
        }
        
        // Fallback to default system behavior
        if (!success) {
            printf("Falling back to default system viewer...\n");
            HINSTANCE result = ShellExecuteW(
                NULL,           // hwnd
                L"open",        // operation
                wideFilePath,   // file
                NULL,           // parameters
                NULL,           // directory
                SW_SHOWNORMAL   // show command
            );

            if ((INT_PTR)result <= 32) {
                printf("Warning: Could not open file with any viewer: %s\n", filePath);
            } else {
                printf("Successfully opened with default viewer: %s\n", filePath);
                success = TRUE;
            }
        }

        free(wideFilePath);
        
        if (success) {
            printf("Successfully previewed: %s\n", filePath);
        }
    }
    
    return 0; // Success
}

#endif // _WIN32