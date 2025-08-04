#ifdef _WIN32
#include "../openfile.h"
#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Windows implementation of the openFiles function
int openFiles(int argc, const char **argv, int fullscreen) {
    if (argc <= 0 || argv == NULL) {
        printf("Error: No files provided to open.\n");
        return 1;
    }

    printf("Opening %d file(s) with Windows Quick Look equivalent...\n", argc);
    
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

        // Try to open file with default associated program
        HINSTANCE result = ShellExecuteW(
            NULL,           // hwnd
            L"open",        // operation
            wideFilePath,   // file
            NULL,           // parameters
            NULL,           // directory
            SW_SHOWNORMAL   // show command
        );

        // Check if ShellExecute succeeded
        if ((INT_PTR)result <= 32) {
            // If default open fails, try with Windows Photo Viewer or similar
            printf("Default open failed for %s, trying alternative viewers...\n", filePath);
            
            // Try Windows Photo Viewer for images
            wchar_t photoViewerCmd[1024];
            swprintf_s(photoViewerCmd, 1024, 
                L"rundll32.exe \"C:\\Program Files\\Windows Photo Viewer\\PhotoViewer.dll\", ImageView_Fullscreen %s", 
                wideFilePath);
            
            STARTUPINFOW si = {0};
            PROCESS_INFORMATION pi = {0};
            si.cb = sizeof(si);
            
            if (!CreateProcessW(NULL, photoViewerCmd, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
                // If Photo Viewer fails, try the modern Photos app
                wchar_t photosCmd[1024];
                swprintf_s(photosCmd, 1024, L"ms-photos:viewer?fileName=%s", wideFilePath);
                
                result = ShellExecuteW(NULL, L"open", photosCmd, NULL, NULL, SW_SHOWNORMAL);
                
                if ((INT_PTR)result <= 32) {
                    printf("Warning: Could not open file with any viewer: %s\n", filePath);
                }
            } else {
                CloseHandle(pi.hProcess);
                CloseHandle(pi.hThread);
            }
        } else {
            printf("Successfully opened: %s\n", filePath);
        }

        free(wideFilePath);
    }

    if (argc > 1) {
        printf("\nOpened %d files. Press Enter to continue...", argc);
        getchar();
    }
    
    return 0; // Success
}

// Alternative implementation using Windows Runtime (for modern Windows 10/11)
// This could be used for a more native Quick Look-like experience
int openFilesWithWindowsRuntime(int argc, const char **argv, int fullscreen) {
    // This would require linking against Windows Runtime libraries
    // and using C++/WinRT or similar for a more modern implementation
    // For now, fall back to the basic implementation
    return openFiles(argc, argv, fullscreen);
}

#endif // _WIN32 