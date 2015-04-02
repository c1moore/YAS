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
char garbage_collected = GC_FALSE;	//Initialize to false.  It is the duty of YACC to set it to GC_TRUE if EOC is reached.
int yerrno = 0;

char *usrnm;						//Username
char *homeDir;						//HOME environmental variable
char *path;							//PATH environmental variable
char **pathDirs = NULL;				//Pointer to the beginning of each NULL terminated directory in the path environmental variable
char *machine;						//Machine name
char newPath = 1;					//Specifies if the path has changed since the last prompt was displayed.
char *cwd;							//Current filepath
int homeDirLength = 0;				//Length of the HOME environmental variable
struct sigaction sigintStopper;		//Signal handler for interruption signal.

void init_yas(void);
void reinit(void);
int getCommands(void);
void expandAliases(void);
void printPrompt(void);
void parsePath(void);
int checkExecutability(char *, char *);
void clean_console(void);
void handleSignalInterrupt(int);

int main() {
	init_yas();

	while(1) {
		printPrompt();

		if(!getCommands()) {
			expandAliases();

			if(builtin != BUILTIN_FALSE) {
				switch(builtin) {
					case BUILTIN_ALIAS:
						if(!alias(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_BYE:
						fprintf(stdout, "Good-bye!\n");
						exit(0);
					case BUILTIN_CD:
						if(!cd(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						} else {
							newPath = 1;
						}
						break;
					case BUILTIN_PRNTENV:
						if(!printenv(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_SETENV:
						if(!env(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_UNALIAS:
						if(!unalias(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_UNENV:
						if(!unenv(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					default:
						fprintf(stderr, "An error occurred recognizing your command.  Check your environmental variables and aliases to make sure you are not referencing a builtin command mistakenly.\n");
						break;
				}
			} else {
				//Create a table to store the full path to the executable files (commands).
				char *commandPaths[num_cmds];

				//Check if all the commands are executable.
				int i = 0;
				for(; i < num_cmds; i++) {
					if(checkExecutability(commandPaths[i], cmdtab[i].C_NAME))
						break;
				}

				if(i < num_cmds) {
					fprintf(stderr, "Error: %s is not a recognized command.\n", cmdtab[i].C_NAME);
					break;
				}
			}

			int i=0;
			for(; i < num_cmds; i++) {
				printf("Command %d name: %s\n", i, cmdtab[i].C_NAME);
				printf("\tNumber of arguments: %d\n", cmdtab[i].C_NARGS);

				int j=0;
				for(; j < cmdtab[i].C_NARGS; j++) {
					printf("\t\tArg %d: %s\n", j, cmdtab[i].C_ARGS_PNTR[j]);
				}

				if(cmdtab[i].C_INPUT.field == C_IO_FILE) {
					printf("\tInput:  %s\n", cmdtab[i].C_INPUT.io.file);
				} else {
					printf("\tInput:  %d\n", cmdtab[i].C_INPUT.io.pointer);
				}

				if(cmdtab[i].C_OUTPUT.field == C_IO_FILE) {
					printf("\tOutput: %s\n", cmdtab[i].C_OUTPUT.io.file);
				} else {
					printf("\tOutput: %d\n", cmdtab[i].C_OUTPUT.io.pointer);
				}

				if(cmdtab[i].C_ERR.field == C_IO_FILE) {
					printf("\tError:  %s\n", cmdtab[i].C_ERR.io.file);
				} else {
					printf("\tError:  %d\n", cmdtab[i].C_ERR.io.pointer);
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

	parsePath();

	//Set the length of the home environmental variable.
	while(homeDir[homeDirLength])
		homeDirLength++;

	//Change current working directory to the home directory.  If that fails, simply use the current directory.
	if(!chdir(homeDir)) {
		cwd = (char *) malloc((homeDirLength + 1) * sizeof(char));
		strcpy(cwd, homeDir);
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
	garbage_collected = GC_FALSE;

	//Check to see if the HOME and PATH environmental variables changed (user switched to super user).  If so update them and set newPath to 1.
	char *newHomeEnv = getenv("HOME");
	char *newPathEnv = getenv("PATH");

	if(!strcmp(newHomeEnv, homeDir)) {
		free(homeDir);
		homeDir = newHomeEnv;

		//Set the length of the home environmental variable.
		homeDirLength = 0;
		while(homeDir[homeDirLength])
			homeDirLength++;

		newPath = 1;
	}

	if(!strcmp(newPathEnv, path)) {
		free(path);
		path = newPathEnv;
		parsePath();
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
}

/**
* Get the next command from YACC.  If there was an error, handle it here and return the status
* to the caller.
*/
int getCommands() {
	int status = yyparse();

	if(status != 0) {
		if(garbage_collected == GC_FALSE)
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
				fprintf(stderr, "\n%s\n", "For more help, type help.");
				return status;
		}
	}

	return status;
}

/**
* Search cmdtab for aliases.  Expand all aliases until they do not reference either another
* alias or environmental variable.  If we have expanded a single alias ALIAS_THRESHOLD times,
* throw an error suspecting the user of trying to create an infinite loop.  Also handle error
* checking:
*		- A builtin command executed through an alias still should not have redirection
*		- If the command includes arguments, the arguments should be parsed correctly.
*		- Tildes should be expanded, too
*/
void expandAliases(void) {
	
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
* Comb over the PATH environmental variable and change each ':' into '\0' and save a pointer
* to the beginning of each path.  Since other Linux system commands do not appear to do this
* theirself, this will make searching system paths for executable files easier.
*/
void parsePath() {
	int i = 1, j = 0;

	//Find the number of directories.
	while(path[j]) {
		if(path[j] == ':')
			i++;

		j++;
	}

	//Allocate space to pathDirs.
	free(pathDirs);
	pathDirs = (char **) malloc((i + 1) * sizeof(char *));
	pathDirs[0] = path;
	pathDirs[i] = 0;

	//Replace ':' with NULL and save pointer to beginning of directory.
	for(i = 1, j = 0; path[j]; j++) {
		if(path[j] == ':') {
			path[j] = 0;
			pathDirs[i] = &path[j+1];
			i++;
		}
	}
}

/**
* Check if a given command is an executable file by checking the directories specified in the
* PATH environmental variable or the path specified by the user.  Only the directories
* specified by the PATH environmental variable will be checked if the command does not contain
* a '/'.  If the file is found and executable, return 0; otherwise, return 1.  If an executable
* file has been found, return the filepath in dest; otherwise, set it equal to NULL.
*/
int checkExecutability(char *dest, char *command) {
	char searchNonPath = 0;		//Search directories not contained in the path?

	int i = 0;
	while(command[i]) {
		if(command[i] == '/') {
			searchNonPath = 1;
		}
		i++;
	}

	//Search files not in PATH first, if applicable
	if(searchNonPath) {
		if(access(command, X_OK) == 0) {
			dest = command;
			return 0;
		}
	}

	for(i = 0; pathDirs[i]; i++) {
		//Determine the length of the full path.
		int j = 0, pathLength = 0;
		while(pathDirs[i][j]) {
			j++;
		}

		pathLength = j;
		
		j = 0;
		while(command[j]) {
			j++;
		}

		pathLength += (j + 1);

		if(command[0] == '/') {
			char *temp = (char *) malloc(pathLength * sizeof(char));
			strcpy(temp, pathDirs[i]);
			strcat(temp, command);

			if(access(temp, X_OK) == 0) {
				dest = temp;
				return 0;
			}

			free(temp);
		} else {
			//We need to add a '/' between pathDirs[i] and command.
			char *temp = (char *) malloc((pathLength + 1) * sizeof(char));
			strcpy(temp, pathDirs[i]);
			strcat(temp, "/");
			strcat(temp, command);

			if(access(temp, X_OK) == 0) {
				dest = temp;
				return 0;
			}

			free(temp);
		}
	}

	return 1;
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