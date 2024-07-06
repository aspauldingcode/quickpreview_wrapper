# Check if clang is available
CLANG_CHECK := $(shell which clang 2>/dev/null)

ifdef CLANG_CHECK
    CC = clang
else
    $(error clang is not installed. Please install clang and try again.)
endif

PROGRAM = openfile

.PHONY: all clean

all: clean $(PROGRAM)

ifeq ($(OS),Windows_NT)
SOURCES = main.c openfile.c windows/openfile_windows.c
else
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
SOURCES = main.c openfile.c linux/openfile_linux.c
else ifeq ($(UNAME_S),Darwin)
SOURCES = main.c openfile.c macos/openfile_macOS.m
CFLAGS = -framework Cocoa -framework Quartz
endif
endif

$(PROGRAM): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(PROGRAM)
