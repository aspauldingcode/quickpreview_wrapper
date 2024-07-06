#include "openfile.h"
#include <stdio.h>
#include <string.h>

int main(int argc, const char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s [-f] <file_path1> [file_path2] ...\n", argv[0]);
        return 1;
    }

    int fullscreen = 0;
    int start_index = 1;

    if (strcmp(argv[1], "-f") == 0) {
        fullscreen = 1;
        start_index = 2;
    }

    if (start_index >= argc) {
        printf("Error: No file paths provided.\n");
        return 1;
    }

    openFiles(argc - start_index, &argv[start_index], fullscreen);
    return 0;
}
