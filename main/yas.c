#include <errno.h>
#include <fcntl.h>
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

struct pfd {
	int fda[2];
};

char bg_mode = BG_MODE_FALSE;
char builtin = BUILTIN_FALSE;
char garbage_collected = GC_FALSE;	//Initialize to false.  It is the duty of YACC to set it to GC_TRUE if EOC is reached.
int yerrno = 0;

char *usrnm;							//Username
char *homeDir;							//HOME environmental variable
char *path;								//PATH environmental variable
char **pathDirs = NULL;					//Pointer to the beginning of each NULL terminated directory in the path environmental variable
char *machine;							//Machine name
char newPath = 1;						//Specifies if the path has changed since the last prompt was displayed.
char *cwd;								//Current filepath
int homeDirLength = 0;					//Length of the HOME environmental variable
struct sigaction killCatcher;			//Signal handler for interruption signal.
struct sigaction errCatcher;			//Signal handler for error program error signals.
int *child_pids = NULL;					//Pointer to all child processes.
volatile sig_atomic_t num_cpids = 0;	//Number of children process PIDs stored in child_pids.
int parent_pid = 0;						//Parent PID
char debugmode = 0;						//Keep track of whether debug mode is on/off
char even = 0;							//Is the number of times the command prompt been printed even or odd.

void init_yas(void);
void reinit(void);
int getCommands(void);
void printPrompt(void);
void parsePath(void);
int checkExecutability(char **, char *);
void clean_console(void);
void killChildren(int);
void warnErr(int);

int main() {
	init_yas();

	while(1) {
		printPrompt();

		if(!getCommands()) {
			if(builtin != BUILTIN_FALSE) {
				switch(builtin) {
					case BUILTIN_ALIAS:
						if(alias(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_BYE:
						fprintf(stdout, "Good-bye!\n" ANSI_COLOR_RESET);
						exit(0);
					case BUILTIN_CD:
						if(cd(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						} else {
							newPath = 1;
						}
						break;
					case BUILTIN_DEBUG:
						if(cmdtab[0].C_NARGS > 1) {
							if(strcasecmp(cmdtab[0].C_ARGS_PNTR[1], "on") == 0) {
								debugmode = 1;
							} else if(strcasecmp(cmdtab[0].C_ARGS_PNTR[1], "off") == 0) {
								debugmode = 0;
							} else {
								debugmode = !debugmode;
							}
						} else {
							debugmode = !debugmode;
						}
						break;
					case BUILTIN_PRNTENV:
						if(printenv(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_SETENV:
						if(env(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_UNALIAS:
						if(unalias(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_UNENV:
						if(unenv(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					case BUILTIN_HELP:
						if(help(cmdtab[0].C_NARGS, cmdtab[0].C_ARGS_PNTR)) {
							//An error occurred.
						}
						break;
					default:
						fprintf(stderr, "An error occurred recognizing your command.  Check your environmental variables and aliases to make sure you are not referencing a builtin command mistakenly.\n");
						break;
				}
			} else {
				//Create a table to store the full path to the executable files (commands).
				char **commandPaths;
				commandPaths = (char **) malloc(num_cmds * sizeof(char *));

				//Check if all the commands are executable.
				int i = 0;
				for(; i < num_cmds; i++) {
					if(checkExecutability(&commandPaths[i], cmdtab[i].C_NAME)) {
						break;
					}
				}

				if(i < num_cmds) {
					fprintf(stderr, "Error: %s is not a recognized internal or external command.\n", cmdtab[i].C_NAME);
					reinit();
					continue;
				}

				child_pids = (int *) malloc(num_cmds * sizeof(int));	//Allocate space to child_pids.
				struct pfd pfds[num_cmds - 1];		//Pipe file descriptors
				int iofiles[3];						//File descriptors for I/O redirection

				for(i = 0; i < num_cmds; i++) {
					//First check I/O redirection points to existing files with proper permissions.
					if(cmdtab[i].C_INPUT.field == C_IO_FILE) {
						if(access(cmdtab[i].C_INPUT.io.file, R_OK)) {
							fprintf(stderr, "I/O Error: Cannot read from file: %s.\n", cmdtab[i].C_INPUT.io.file);
							break;
						}

						iofiles[0] = open(cmdtab[i].C_INPUT.io.file, O_RDONLY);
					}
					if(cmdtab[i].C_OUTPUT.field == C_IO_FILE) {
						//If the file doesn't exist or if the file should be overwritten use creat.
						if(access(cmdtab[i].C_OUTPUT.io.file, F_OK) || cmdtab[i].C_INPUT.concat == C_IO_OW) {
							iofiles[1] = creat(cmdtab[i].C_OUTPUT.io.file, 0000666);
						} else if(access(cmdtab[i].C_OUTPUT.io.file, W_OK)) {
							fprintf(stderr, "I/O Error: Cannot write to file: %s.\n", cmdtab[i].C_OUTPUT.io.file);
							break;
						} else {
							//The file exists and should be appended to.
							iofiles[1] = open(cmdtab[i].C_OUTPUT.io.file, O_WRONLY | O_APPEND);
						}
					}
					if(cmdtab[i].C_ERR.field == C_IO_FILE) {
						//If the file doesn't exist use creat.
						if(access(cmdtab[i].C_ERR.io.file, F_OK)) {
							iofiles[2] = creat(cmdtab[i].C_ERR.io.file, 0000666);
						}else if(access(cmdtab[i].C_ERR.io.file, W_OK)) {
							fprintf(stderr, "I/O Error: Cannot write to error file: %s.\n", cmdtab[i].C_ERR.io.file);
							break;
						} else {
							//The file exists and should be appended to.
							iofiles[2] = open(cmdtab[i].C_ERR.io.file, O_WRONLY | O_APPEND);
						}
					}

					//First command
					if(i == 0) {
						//No need to create pipes.
						if(num_cmds == 1) {
							if((child_pids[i] = fork()) == -1) {
								//Error occurred forking process
								fprintf(stderr, "Error: Could not fork shell.\n");

								break;
							}

							num_cpids++;

							//In the child process
							if(child_pids[i] == 0) {
								//Check I/O redirection
								if(cmdtab[i].C_INPUT.field == C_IO_FILE) {
									close(0);					//Close standard input
									dup(iofiles[0]);			//Set stdin
									close(iofiles[0]);			//Close unneed I/O
								}
								if(cmdtab[i].C_OUTPUT.field == C_IO_FILE) {
									close(1);					//Close standard output
									dup(iofiles[1]);			//Set stdout
									close(iofiles[1]);			//Close unneed I/O
								}
								if(cmdtab[i].C_ERR.field == C_IO_FILE) {
									close(2);					//Close standard error
									dup2(iofiles[2], 2);		//Set stderr
									close(iofiles[2]);			//Close unneed I/O
								}

								//Execute the command and exit
								execv(commandPaths[i], cmdtab[i].C_ARGS_PNTR);
								exit(0);
							}

							//Close unneeded I/O
							if(cmdtab[i].C_INPUT.field == C_IO_FILE) {
								close(iofiles[0]);
							}
							if(cmdtab[i].C_OUTPUT.field == C_IO_FILE) {
								close(iofiles[1]);
							}
							if(cmdtab[i].C_ERR.field == C_IO_FILE) {
								close(iofiles[2]);
							}

						} else {
							//This is the first command in a pipe

							if(pipe(pfds[i].fda)) {
								//Error occurred creating pipe.
								fprintf(stderr, "Error: Piping failed.\n");
								break;
							}

							if((child_pids[i] = fork()) == -1) {
								//Error occurred forking process.
								fprintf(stderr, "Error: Could not fork shell.\n");

								//Close I/O created by pipe()
								close(pfds[i].fda[0]);
								close(pfds[i].fda[1]);

								break;
							}

							num_cpids++;

							if(child_pids[i] == 0) {
								//In the child process
								close(1);					//Close standard output
								dup(pfds[i].fda[1]);		//Set end of pipe as stdout

								//Check I/O redirection
								if(cmdtab[i].C_INPUT.field == C_IO_FILE) {
									close(0);					//Close standard input
									dup(iofiles[0]);			//Set stdin
									close(iofiles[0]);			//Close unneed I/O
								}
								if(cmdtab[i].C_ERR.field == C_IO_FILE) {
									close(2);					//Close standard error
									dup(iofiles[2]);			//Set stderr
									close(iofiles[2]);			//Close unneed I/O
								}

								//Close unneeded I/O
								close(pfds[i].fda[0]);
								close(pfds[i].fda[1]);

								//Execute the command
								execv(commandPaths[i], cmdtab[i].C_ARGS_PNTR);
								exit(0);
							}

							//Close unneeded I/O
							if(cmdtab[i].C_INPUT.field == C_IO_FILE) {
								close(iofiles[0]);
							}
							if(cmdtab[i].C_ERR.field == C_IO_FILE) {
								close(iofiles[2]);
							}
						}
					} else if(i >= (num_cmds - 1)) {
						//Last command iff there is more than 1 command
						if((child_pids[i] = fork()) == -1) {
							//Error occurred forking process
							fprintf(stderr, "Error: Could not fork shell.\n");

							//Close I/O created from last pipe
							close(pfds[i-1].fda[0]);
							close(pfds[i-1].fda[1]);

							break;
						}

						num_cpids++;

						if(child_pids[i] == 0) {
							//In the child process
							close(0);				//Close standard input
							dup(pfds[i-1].fda[0]);	//Set beginning of pipe as stdin
								
							//Check I/O redirection
							if(cmdtab[i].C_OUTPUT.field == C_IO_FILE) {
								close(1);					//Close standard output
								dup(iofiles[1]);			//Set stdout
								close(iofiles[1]);			//Close unneed I/O
							}
							if(cmdtab[i].C_ERR.field == C_IO_FILE) {
								close(2);					//Close standard error
								dup(iofiles[2]);			//Set stderr
								close(iofiles[2]);			//Close unneed I/O
							}

							//Close unneeded I/O
							close(pfds[i-1].fda[0]);
							close(pfds[i-1].fda[1]);

							//Execute the command
							execv(commandPaths[i], cmdtab[i].C_ARGS_PNTR);
							exit(0);
						}

						//Close unneeded I/O
						if(cmdtab[i].C_OUTPUT.field == C_IO_FILE) {
							close(iofiles[1]);
						}
						if(cmdtab[i].C_ERR.field == C_IO_FILE) {
							close(iofiles[2]);
						}
					} else {
						//Commands in middle of pipe line
						if(pipe(pfds[i].fda)) {
							//Error occurred creating pipe.
							fprintf(stderr, "Error: Piping failed.\n");

							//Close all I/O created by pipe up to this point
							int j = 0;
							for(; j < i; j++) {
								close(pfds[j].fda[0]);
								close(pfds[j].fda[1]);
							}

							break;
						}

						if((child_pids[i] = fork()) == -1) {
							//Error occurred forking process
							fprintf(stderr, "Error: Could not fork shell.\n");

							//Close all I/O created by pipe up to this point
							int j = 0;
							for(; j < i; j++) {
								close(pfds[j].fda[0]);
								close(pfds[j].fda[1]);
							}

							break;
						}

						num_cpids++;

						if(child_pids[i] == 0) {
							//In the child process

							//Setup stdout for the process.  Output goes through pipe formed in this iteration
							close(1);
							dup(pfds[i].fda[1]);

							//Setup stdin for the process.  Input is obtained from previous command (pipe from previous iteration).
							close(0);
							dup(pfds[i-1].fda[0]);

							//Check I/O redirection
							if(cmdtab[i].C_ERR.field == C_IO_FILE) {
								close(2);					//Close standard error
								dup(iofiles[2]);			//Set stderr
								close(iofiles[2]);			//Close unneed I/O
							}

							//Close unneeded I/O
							close(pfds[i].fda[0]);
							close(pfds[i].fda[1]);
							close(pfds[i-1].fda[0]);
							close(pfds[i-1].fda[1]);

							//Execute the command
							execv(commandPaths[i], cmdtab[i].C_ARGS_PNTR);
							exit(0);
						}

						//Close unneeded I/O
						if(cmdtab[i].C_ERR.field == C_IO_FILE) {
							close(iofiles[2]);
						}
					}
				}

				/**
				* The pipeline has been fully created.  If it was a success and the user specifed
				* to run the process in the foreground, wait on all the child processes to finish;
				* otherwise, continue executing.
				*/
				if(i == num_cmds && bg_mode == BG_MODE_FALSE) {
					int j = 0;
					for(; j < (num_cmds - 1); j++) {
						close(pfds[j].fda[0]);
						close(pfds[j].fda[1]);
					}

					//Wait for all children to DIE.
					for(j = 0; j < num_cmds; j++) {
						int status[1];
						waitpid((pid_t) child_pids[j], status, WUNTRACED);

						if(WIFSIGNALED(*status)) {
							int sig_num = WTERMSIG(*status);
							switch(sig_num) {
								case SIGSEGV:
									fprintf(stderr, "Crap... That wasn't supposed to happen.\n\nSegmentation fault (something probably tried accessing memory that didn't belong to it).\n");
									break;
								case SIGILL:
									fprintf(stderr, "Illegal instruction (something tried executing something that was not a function).\n");
									break;
								case SIGBUS:
									fprintf(stderr, "Invalid pointer dereferenced (make sure pointers actually point to something before freeing them).\n");
									break;
								case SIGFPE:
									fprintf(stderr, "Floating point error.\n");
									break;
								case SIGSYS:
									fprintf(stderr, "Bad system call.\n");
									break;
							}

							#ifdef WCOREDUMP
								if(WCOREDUMP(status)) {
									fprintf(stderr, "Core dumped.\n");
								}
							#endif
						}

						if(WIFSTOPPED(*status)) {
							int sig_num = WSTOPSIG(*status);
							switch(sig_num) {
								case SIGSEGV:
									fprintf(stderr, "Crap... That wasn't supposed to happen.\n\nSegmentation fault (something probably tried accessing memory that didn't belong to it).\n");
									break;
								case SIGILL:
									fprintf(stderr, "Illegal instruction (something tried executing something that was not a function).\n");
									break;
								case SIGBUS:
									fprintf(stderr, "Invalid pointer dereferenced (make sure pointers actually point to something before freeing them).\n");
									break;
								case SIGFPE:
									fprintf(stderr, "Floating point error.\n");
									break;
								case SIGSYS:
									fprintf(stderr, "Bad system call.\n");
									break;
							}

							#ifdef WCOREDUMP
								if(WCOREDUMP(status)) {
									fprintf(stderr, "Core dumped.\n");
								}
							#endif
						}
					}
				}
			}

			if(debugmode) {
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
		}

		reinit();
	}
}

/**
* Initialize global variables used by YAS and disable Ctrl-C from terminating the shell.
*/
void init_yas(void) {
	//Set current/parent PID.
	parent_pid = getpid();

	//Disable Ctrl-C (interrupts) for this process and kill all running children.
	memset(&killCatcher, 0, sizeof(killCatcher));
	killCatcher.sa_handler = killChildren;
	sigemptyset(&(killCatcher.sa_mask));
	killCatcher.sa_flags = SA_RESTART;
	
	sigaction(SIGINT, &killCatcher, NULL);
	sigaction(SIGTERM, &killCatcher, NULL);
	sigaction(SIGQUIT, &killCatcher, NULL);
	sigaction(SIGHUP, &killCatcher, NULL);
	sigaction(SIGTSTP, &killCatcher, NULL);

	//Catch program errors
	memset(&errCatcher, 0, sizeof(errCatcher));
	errCatcher.sa_handler = warnErr;
	sigemptyset(&errCatcher.sa_mask);
	errCatcher.sa_flags = SA_RESTART;

	sigaction(SIGILL, &errCatcher, NULL);
	sigaction(SIGSEGV, &errCatcher, NULL);
	sigaction(SIGBUS, &errCatcher, NULL);
	sigaction(SIGABRT, &errCatcher, NULL);
	sigaction(SIGIOT, &errCatcher, NULL);
	sigaction(SIGTRAP, &errCatcher, NULL);
	sigaction(SIGSYS, &errCatcher, NULL);
	sigaction(SIGPIPE, &errCatcher, NULL);
	sigaction(SIGFPE, &errCatcher, NULL);

	//Clear the console.
	system("echo \033c; echo \x1Bc; tput clear;");		//Not supposed to use system, but this is solely for aesthetic reasons.  Has no functionality, just clears the terminal's output.

	//Display welcome message.
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

	//Get the HOME and PATH environmental variables.  Do not just save pointer to location in environmental variables so we can determine if they have changed.
	path = (char *) malloc((strlen(getenv("PATH")) + 1) * sizeof(char));
	homeDir = (char *) malloc((strlen(getenv("HOME")) + 1) * sizeof(char));
	strcpy(path, getenv("PATH"));
	strcpy(homeDir, getenv("HOME"));

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
	//Free space allocated to child_pids and set pointer to NULL.
	num_cpids = 0;
	free(child_pids);
	child_pids = NULL;

	num_cmds = 0;
	yerrno = 0;
	bg_mode = BG_MODE_FALSE;
	builtin = BUILTIN_FALSE;
	garbage_collected = GC_FALSE;

	//Check to see if the HOME and PATH environmental variables changed (user switched to super user).  If so update them and set newPath to 1.
	char *newHomeEnv = getenv("HOME");
	char *newPathEnv = getenv("PATH");

	if(strcmp(newHomeEnv, homeDir)) {
		free(homeDir);
		homeDir = (char *) malloc((strlen(newHomeEnv) + 1) * sizeof(char));
		strcpy(homeDir, newHomeEnv);

		//Set the length of the home environmental variable.
		homeDirLength = 0;
		while(homeDir[homeDirLength])
			homeDirLength++;

		//A tilde may or may not be required now that the home directory has changed.
		newPath = 1;
	}

	if(strcmp(newPathEnv, path)) {
		free(path);
		path = (char *) malloc((strlen(newPathEnv) + 1) * sizeof(char));
		strcpy(path, newPathEnv);
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
				fprintf(stderr, ANSI_COLOR_RED "\n%s", "For more help, type help cmd.");
				return status;
			case IO_ERR:
				fprintf(stderr, ANSI_COLOR_RED "\n%s", "For more help, type help io.");
				return status;
			case USER_ERR:
				fprintf(stderr, ANSI_COLOR_RED "\n%s", "For more help, type help.");
				return status;
			case ARG_ERR:
				fprintf(stderr, ANSI_COLOR_RED "\n%s", "For more help, type help arg.");
				return status;
			default:
				fprintf(stderr, ANSI_COLOR_RED "\n%s", "For more help, type help.");
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

	if(even) {
		fprintf(stdout, ANSI_COLOR_BLUE "\n%s@%s:%s> ", usrnm, machine, cwd);
		fflush(stdout);
	} else {
		fprintf(stdout, ANSI_COLOR_RESET "\n%s@%s:%s> ", usrnm, machine, cwd);
		fflush(stdout);
	}

	even = (++even) % 2;
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
int checkExecutability(char **dest, char *command) {
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
			*dest = command;
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
				*dest = (char *) malloc((pathLength + 1) * sizeof(char));
				strcpy(*dest, temp);
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
				*dest = (char *) malloc((pathLength + 1) * sizeof(char));
				strcpy(*dest, temp);
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
void killChildren(int sig_num) {
	//Only execute this if we are in the parent process.
	if(parent_pid = getpid()) {
		int i = 0;

		//Kill all child processes.
		while(i < num_cpids) {
			kill(child_pids[i++], sig_num);
		}
	} else {
		//If in a child process, do the default action.
		SIG_DFL(sig_num);
	}
}

void warnErr(int sig_num) {
	//Only execute if in the parent process.
	if(parent_pid = getpid()) {
		// switch(sig_num) {
		// 	case SIGSEGV:
		// 		fprintf(stderr, "Crap... That wasn't supposed to happen.\n\nSegmentation fault (something probably tried accessing memory that didn't belong to it).\n");
		// 		break;
		// 	case SIGILL:
		// 		fprintf(stderr, "Illegal instruction (something tried executing something that was not a function).\n");
		// 		break;
		// 	case SIGBUS:
		// 		fprintf(stderr, "Invalid pointer dereferenced (make sure pointers actually point to something before freeing them).\n");
		// 		break;
		// 	case SIGFPE:
		// 		fprintf(stderr, "Floating point error.\n");
		// 	case SIGSYS:
		// 		fprintf(stderr, "Bad system call.\n");
		// 		break;
		// 	default:
		// 		fprintf(stderr, "Error number: %d.  (Check program signal errors for more information)\n", sig_num);
		// 		break;
		// }
	} else {
		//If in a child process, do the default action.
		SIG_DFL(sig_num);
	}
}