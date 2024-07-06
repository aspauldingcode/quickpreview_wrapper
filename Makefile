CC = clang
CFLAGS = -framework Cocoa -framework Quartz
PROGRAM = openfile

.PHONY: all clean

all: clean $(PROGRAM)

$(PROGRAM): openfile.m
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(PROGRAM)
