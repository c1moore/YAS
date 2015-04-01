CC = cc

INCLUDES= $(wildcard ../includes/*.h)
COMMANDSFILES = $(wildcard ../commands/*.c)
YASFILES = lex.yy.c y.tab.c yas.c
CFLAGS = -I ../commands -I ../includes

all: yas

lex.yy.c: lex.l
	lex lex.l

y.tab.c: yas_grammar.y
	yacc -d yas_grammar.y

cmnds.0: $(COMMANDSFILES)
	$(CC) $(COMMANDSFILES) -o cmnds.o $(CFLAGS)

yas: $(COMMANDSFILES) $(YASFILES) $(INCLUDES) 
	$(CC) $(YASFILES) $(COMMANDSFILES) -o yas $(CFLAGS)

clean:
	rm -f lex.yy.c y.tab.c yas.o y.tab.h