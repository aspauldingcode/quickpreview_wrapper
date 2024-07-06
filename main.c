#include "openfile.h"
#include <stdio.h>

int main(int argc, const char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s /path/to/your/file\n", argv[0]);
        return 1;
    }
    openFile(argv[1]);
    return 0;
}
