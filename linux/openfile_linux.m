#include "openfile.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void openFile(const char *filePath) {
    // Linux specific implementation using sushi
    printf("Opening file on Linux with sushi: %s\n", filePath);
    
    // Check if filePath is empty
    if (filePath == NULL || strlen(filePath) == 0) {
        fprintf(stderr, "Error: No file path provided.\n");
        return;
    }

    // Construct the command
    char command[256];
    snprintf(command, sizeof(command), "sushi \"%s\"", filePath);

    // Execute the command
    int result = system(command);

    // Check the result
    if (result != 0) {
        fprintf(stderr, "Error: Failed to open file with sushi.\n");
        fprintf(stderr, "Usage:\n    sushi FILE\n");
        fprintf(stderr, "    Opens FILE in a NautilusPreviewer window.\n");
    }
}
