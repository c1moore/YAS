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

yas: $(COMMANDSFILES) $(YASFILES) $(INCLUDES) 
	$(CC) $(YASFILES) $(COMMANDSFILES) -o yas $(CFLAGS)

clean:
	rm -f lex.yy.c y.tab.c yas.o y.tab.h yas yas_grammar.tab.c yas_grammar.tab.h ../commands/alias ../commands/cd ../commands/printenv ../commands/setenv ../commands/unalias ../commands/unsetenv