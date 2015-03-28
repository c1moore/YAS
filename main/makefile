CC = gcc

INCLUDES= yas.h yas_errors.h yas_limits.h yas_structures.h
DIR = ../includes ../commands
FILES = alias.c cd.c printenv.c setenv.c unalias.c unsetenv.c yas.c
CFLAGS = -I$(DIR)

FILES = in_one.c in_two.c
SOURCES = SOURCES=$(wildcard ../**/*.c) 
OUT_EXE = out_executable

all: $(INCLUDES)
	$(CC) -o YAS.o $(FILES) $(CFLAGS)

clean:
	rm -f *.o core