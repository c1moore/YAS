CC = cc

INCLUDES= $(wildcard includes/*.h)
COMMANDSFILES = $(wildcard commands/*.c)
YASFILES = main/lex.yy.c main/y.tab.c main/yas.c
CFLAGS = -I commands/ -I includes/

all: yas

main/lex.yy.c: main/lex.l
	lex -o main/lex.yy.c main/lex.l 

main/y.tab.c: main/yas_grammar.y
	yacc -o main/y.tab.c -d main/yas_grammar.y

yas: $(COMMANDSFILES) $(YASFILES) $(INCLUDES) 
	$(CC) $(YASFILES) $(COMMANDSFILES) -lm -o yas $(CFLAGS) 

clean:
	rm -f main/lex.yy.c main/y.tab.c main/yas.o main/y.tab.h yas main/yas_grammar.tab.c main/yas_grammar.tab.h
