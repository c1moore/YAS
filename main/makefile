CC = gcc

INCLUDES= ../includes/yas.h ../includes/yas_errors.h ../includes/yas_limits.h ../includes/yas_structures.h
DIR = ../includes ../commands
FILES = alias.c cd.c printenv.c setenv.c unalias.c unsetenv.c yas.c
CFLAGS = -I$(DIR)

FILES = in_one.c in_two.c
SOURCES = SOURCES=$(wildcard ../**/*.c) 
OUT_EXE = out_executable

build: $(INCLUDES)
	$(CC) -o YAS.o $(FILES) $(CFLAGS)

clean:
	rm -f *.o core