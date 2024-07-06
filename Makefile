CC = clang
CFLAGS = -framework Cocoa -framework Quartz
PROGRAM = openfile

.PHONY: all clean

all: clean $(PROGRAM)

$(PROGRAM): main.c openfile.c openfile_macOS.m openfile_windows.c openfile_linux.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(PROGRAM)
