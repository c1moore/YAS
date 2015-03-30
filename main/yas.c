#include <pwd.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <unistd.h>
#include "yas.h"
#include "y.tab.h"


char bg_mode = BG_MODE_FALSE;
char builtin = BUILTIN_FALSE;
int yerrno = 0;

char *usrnm;						//Username
char *homeDir;						//HOME environmental variable
char *path;							//PATH environmental variable
char *machine;						//Machine name
char newPath = 1;					//Specifies if the path has changed since the last prompt was displayed.
char *cwd;							//Current filepath
int homeDirLength = 0;				//Length of the HOME environmental variable
struct sigaction sigintStopper;		//Signal handler for interruption signal.

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
			int i=0;
			for(; i < num_cmds; i++) {
				printf("Command %d name: %s\n", i, cmdtab[i].C_NAME);
				printf("\tNumber of arguments: %d\n", cmdtab[i].C_NARGS);

				int j=0;
				for(; j < cmdtab[i].C_NARGS; j++) {
					printf("\t\tArg %d: %s\n", j, cmdtab[i].C_ARGS_PNTR[j]);
				}

				if(cmdtab[i].C_INPUT.field == C_IO_FILE) {
					printf("\tInput: %s\n", cmdtab[i].C_INPUT.io.file);
				} else {
					printf("\tInput: %d\n", cmdtab[i].C_INPUT.io.pointer);
				}

				if(cmdtab[i].C_OUTPUT.field == C_IO_FILE) {
					printf("\tOutput: %s\n", cmdtab[i].C_OUTPUT.io.file);
				} else {
					printf("\tOutput: %d\n", cmdtab[i].C_OUTPUT.io.pointer);
				}

				if(cmdtab[i].C_ERR.field == C_IO_FILE) {
					printf("\tError: %s\n", cmdtab[i].C_ERR.io.file);
				} else {
					printf("\tError: %d\n", cmdtab[i].C_ERR.io.pointer);
				}
			}
		}

		reinit();
	}
}

/**
* Initialize global variables used by YAS and disable Ctrl-C from terminating the shell.
*/
void init_yas(void) {
	//Disable Ctrl-C (interrupts).
	sigintStopper.sa_handler = handleSignalInterrupt;
	sigemptyset(&(sigintStopper.sa_mask));
	sigintStopper.sa_flags = 0;
	
	sigaction(SIGINT, &sigintStopper, NULL);

	//Clear the console and display welcome messages.
	system("echo \033c; echo \x1Bc; tput clear;");

	fprintf(stdout, "%s\n\n", YAS_BANNER);

	//Initialize counts and yerrno.
	num_cmds = 0;
	num_aliases = 0;
	yerrno = 0;

	//Initialize the head of the alias linked list.
	alias_head = (struct yas_alias *) malloc(sizeof(struct yas_alias));
	alias_head->alias = calloc(1, sizeof(char));
	alias_head->cmd = calloc(1, sizeof(char));
	alias_head->next = 0;

	//Obtain the username.
	struct passwd *user = getpwuid( geteuid() );
	if(user == NULL) {
		fprintf(stderr, "Error initializing YAS. Exiting...\n");
		exit(-1);
	}

	int length = 0;
	while(user->pw_name[length++]);
	usrnm = (char *) malloc((length + 1) * sizeof(char));
	strcpy(usrnm, user->pw_name);

	//Obtain the machine name.
	char *hostName = (char *) malloc(HOST_NAME_MAX);
	gethostname(hostName, HOST_NAME_MAX);
	machine = hostName;

	//Get the HOME and PATH environmental variables.
	path = getenv("PATH");
	homeDir = getenv("HOME");

	//Set the length of the home environmental variable.
	while(homeDir[homeDirLength])
		homeDirLength++;

	//Change current working directory to the home directory.  If that fails, simply use the current directory.
	if(!chdir(homeDir)) {
		cwd = homeDir;
	} else {
		getcwd(cwd, 0);
	}
}

/**
* These commands need to be run each time a command is executed.
*/
void reinit(void) {
	num_cmds = 0;
	yerrno = 0;
	bg_mode = BG_MODE_FALSE;
	builtin = BUILTIN_FALSE;

	//Check to see if the HOME and PATH environmental variables changed (user switched to super user).  If so update them and set newPath to 1.
	char *newHomeEnv = getenv("HOME");
	char *newPathEnv = getenv("PATH");

	if(strcmp(newHomeEnv, homeDir)) {
		free(homeDir);
		homeDir = newHomeEnv;

		//Set the length of the home environmental variable.
		homeDirLength = 0;
		while(homeDir[homeDirLength])
			homeDirLength++;

		newPath = 1;
	}

	if(strcmp(newPathEnv, path)) {
		free(path);
		path = newPathEnv;
	}

	//Check to see if the user has changed and update usrnm if so.
	struct passwd *user = getpwuid( geteuid() );
	if(user == NULL) {
		fprintf(stderr, "Error initializing YAS. Exiting...\n");
		exit(-1);
	} else {
		if(strcmp(usrnm, user->pw_name)) {
			//The user name has changed.
			free(usrnm);

			int length = 0;
			while(user->pw_name[length++]);
			usrnm = (char *) malloc((length + 1) * sizeof(char));

			strcpy(usrnm, user->pw_name);
		}
	}

	//clean_console();
}

/**
* Get the next command from YACC.  If there was an error, handle it here and return the status
* to the caller.
*/
int getCommands() {
	int status = yyparse();
	//clean_console();


	//fprintf(stderr, "%d\n", status);

	if(status != 0) {
		clean_console();

		switch(yerrno) {
			case CMD_ERR:
				fprintf(stderr, "\n%s\n", "For more help, type help cmd.");
				return status;
			case IO_ERR:
				fprintf(stderr, "\n%s\n", "For more help, type help io.");
				return status;
			case USER_ERR:
				fprintf(stderr, "\n%s\n", "For more help, type help user.");
				return status;
			case ARG_ERR:
				fprintf(stderr, "\n%s\n", "For more help, type help arg.");
				return status;
			default:
				return status;
		}
	}

	return status;
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
		char *filepath = (char *) malloc((PATH_MAX + 1) * sizeof(char));
		getcwd(filepath, PATH_MAX + 1);

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

			cwd[j] = 0;

			free(filepath);
		} else {
			int length = 0;
			while(filepath[length++]);

			filepath = (char *) realloc(filepath, (length + 1) * sizeof(char));

			cwd = filepath;
		}

		newPath = 0;
	}

	fprintf(stdout, "%s@%s:%s> ", usrnm, machine, cwd);
	fflush(stdout);
}

/**
* If an error occurs, clean the console by calling lex until it has read everything the user
* typed after the error.
*/
void clean_console(void) {
	int rtoken;
	do {
		rtoken = yylex();
	} while(rtoken != 0 && rtoken != EOC);
}

/**
* Handle when Ctrl-C is pressed.  For now, simply ignore it.  Should be extended to kill the
* currently running command.
*/
void handleSignalInterrupt(int param) {
	SIG_IGN(param);
}