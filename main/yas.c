#include <pwd.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <unistd.h>
#include "yas.h"
#include "y.tab.h"

extern char *usrnm;					//Username
extern char *homeDir;				//HOME environmental variable
extern char *path;					//PATH environmental variable
char *machine;						//Machine name
char newPath = 0;					//Specifies if the path has changed since the last prompt was displayed.
char *cwd;							//Current filepath
int homeDirLength = 0;				//Length of the HOME environmental variable
struct sigaction *sigintStopper;	//Signal handler for interruption signal.

void init_yas(void);
void reinit(void);
int getCommands(void);
void clean_console(void);
void handleSignalInterrupt(int);
void printPrompt(void);

int main() {
	init_yas();

	while(1) {
		printPrompt();
		if(!getCommands()) {

		}

		reinit();
	}
}

/**
* Initialize global variables used by YAS and disable Ctrl-C from terminating the shell.
*/
void init_yas(void) {
	//Disable Ctrl-C (interrupts).
	sigintStopper->sa_handler = handleSignalInterrupt;
	sigemptyset(&(sigintStopper->sa_mask));
	sigintStopper->sa_flag = 0;
	
	sigaction(SIGINT, sigintStopper, NULL);

	//Clear the console.
	write(1, "\E[H\E[2J",7);

	//Initialize counts.
	num_cmds = 0;
	num_aliases = 0;

	//Initialize the head of the alias linked list.
	alias_head = (yas_alias *) malloc(sizeof(struct yas_alias));
	alias_head->alias = calloc(1, sizeof char);
	alias_head->cmd = calloc(1, sizeof char);
	alias_head->next = 0;

	//Obtain the username.
	struct passwd *user = getpwuid( geteuid() );
	if(user == NULL) {
		fprintf(stderr, "Error initializing YAS. Exiting...\n");
		exit(-1);
	}

	int length = 0;
	while(user->pw_name[length++]);
	usrnm = (char *) malloc(length * sizeof char);
	strcpy(usrnm, user->pw_name);

	//Obtain the machine name.
	struct utsname *unameData;
	if(uname(unameData) == NULL) {
		fprintf(stderr, "Error initializing YAS.  Exiting...\n");
		exit(-1);
	}

	length = 0;
	while(unameData->nodename[length++]);
	machine = (char *) malloc(length * sizeof char);
	strcpy(machine, unameData->nodename);

	//Get the HOME and PATH environmental variables.
	path = getenv("PATH");
	homeDir = getenv("HOME");

	//Set the length of the home environmental variable.
	while(homeDir[homeDirLength++]);

	//Change current working directory to the home directory.  If that fails, simply use the current directory.
	if(!chdir(homeDir)) {
		cwd = homeDir;
	} else {
		cwd = get_current_dir_name();
	}

	clean_console();
}

void reinit(void) {
	num_cmds = 0;
	bg_mode = BG_MODE_FALSE;
	builtin = BUILTIN_FALSE;
}

/**
* Get the next command from YACC.  If there was an error, handle it here and return the status
* to the caller.
*/
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
* Simply print the prompt.  The prompt will be of the form 'user@machineName: path> '.  Since
* the prompt uses the path, it will have to be checked every time the prompt is displayed.
* The variable newPath will keep track of whether or not cwd needs to be updated to reflect
* a new current working directory (this means each time cd is called, we need to set it to
* true).
*/
void printPrompt() {
	if(newPath) {
		//The current working directory has changed, update cwd.
		char *filepath = get_current_dir_name();

		int i = 0;
		while(filepath[i] && homeDir[i]) {
			if(filepath[i] ==  homeDir[i]) {
				i++;
			} else {
				break;
			}
		}

		if(i == homeDirLength) {
			//The beginning of the path is the home directory, replace it with a '~'
			cwd[0] = '~';

			int j = 1;
			while(filepath[i])
				cwd[j++] = filepath[i++];

			free(filepath);
		} else {
			cwd = filepath;
		}

	}

	fprintf(stdout, "%s@%s: %s> ", usrnm, machine, cwd);
	fflush(stdout);
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