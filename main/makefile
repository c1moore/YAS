CC = cc

INCLUDES= ../includes/yas.h ../includes/yas_errors.h ../includes/yas_limits.h ../includes/yas_structures.h
DIR = ../includes ../commands
YASFILES = lex.yy.c y.tab.c yas.c
CFLAGS = -I$(DIR)

all: yas

lex.yy.c: lex.l
	lex lex.l

y.tab.c: yas_grammar.y
	yacc -d yas_grammar.y

yas: $(YASFILES) $(INCLUDES) 
	$(CC) $(YASFILES) -o yas -I ../includes -I ../commands

clean:
	rm -f lex.yy.c y.tab.c yas.o y.tab.h