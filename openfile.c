#include "openfile.h"
#include <stdio.h>

#ifdef __APPLE__
#include "openfile_macOS.c"
#elif defined(_WIN32) || defined(_WIN64)
#include "openfile_windows.c"
#elif defined(__linux__)
#include "openfile_linux.c"
#else
void openFile(const char *filePath) {
    printf("Unsupported platform\n");
}
#endif

