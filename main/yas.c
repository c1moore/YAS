#include <stdlib.h>
#include <string.h>
#include <types.h>
#include <signal.h>
#include "yas.h"
#include "y.tab.h"

void init_yas(void);
void reinit(void);
int getCommands(void);
void clean_console(void);



int main() {
	init_yas();

	while(1) {
		getCommands()
	}
}

/**
* Initialize global variables used by YAS and disable Ctrl-C from terminating the shell.
*/
void init_yas(void) {
	signal(SIGINT, handleSignalInterrupt);

	num_cmds = 0;
	num_aliases = 0;

	alias_head = (yas_alias *) malloc(sizeof(struct yas_alias));
	alias_head->alias = calloc(1, sizeof char);
	alias_head->cmd = calloc(1, sizeof char);
	alias_head->next = 0;

	clean_console();
}

void reinit(void) {
	num_cmds = 0;
	bg_mode = BG_MODE_FALSE;
	builtin = BUILTIN_FALSE;
}

int getCommands() {
	int status = yyparse();

	if(status != 0) {
		clean_console();
	}

	switch(status) {
		case: CMD_ERR
			fprintf(stderr, "\n%s\n", "For more help, type help cmd.");
			return status;
		case: IO_ERR
			fprintf(stderr, "\n%s\n", "For more help, type help io.");
			return status;
		case: USER_ERR
			fprintf(stderr, "\n%s\n", "For more help, type help user.");
			return status;
		case: ARG_ERR
			fprintf(stderr, "\n%s\n", "For more help, type help arg.");
			return status;
		default:
			return status;
	}
}

/**
* If an error occurs, clean the console by calling lex until it has read everything the user
* typed after the error.
*/
void clean_console(void) {
	while(yylex() != 0);
}

/**
* Handle when Ctrl-C is pressed.  For now, simply ignore it.  Should be extended to kill the
* currently running command.
*/
void handleSignalInterrupt(int param) {
	SIG_IGN(param);
}