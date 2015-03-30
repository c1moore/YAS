CC = gcc

INCLUDES= ../includes/yas.h ../includes/yas_errors.h ../includes/yas_limits.h ../includes/yas_structures.h
DIR = ../includes ../commands
FILES = yas.c
CFLAGS = -I$(DIR)

FILES = in_one.c in_two.c
SOURCES = SOURCES=$(wildcard ../**/*.c) 
OUT_EXE = out_executable

all: yas.o

lex.yy.c: lex.l
	lex lex.l

y.tab.c: yas_grammar.y
	yacc -d yas_grammar.y

yas.o: yas.c $(INCLUDES) y.tab.c
	$(CC) -o yas.o yas.c $(CFLAGS)

clean:
	rm -f lex.yy.c