%{
	#include <sys/types.h>
	#include <pwd.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#include "../includes/yas.h"

	static const struct cmd empty_cmd = {C_NAME_INIT, 1, 0, 0, C_IO_IN_INIT, C_IO_OUT_INIT, C_IO_ERR_INIT};
	struct cmd new_cmd = {C_NAME_INIT, 1, 0, 0, C_IO_IN_INIT, C_IO_OUT_INIT, C_IO_ERR_INIT};

	extern int yerrno;
	int num_resizes = 0, pntr_resizes = 0;								//Keep track of the number of times the C_ARGS and C_ARGS_PNTR has been resized.
	char *argument;														//Used for tilde expansion of arguments.
	char io_in_set = 0, io_out_set = 0, io_err_set = 0, io_pipe = 0;	//Determine if I/O has already been set.
	char reached_eoc = 0;												//Determine if '\n' has been reached (should exit if reached_eoc == 1).

	void checkAndAlloc();
	void reallocArgs();
	void replaceTilde(char *);
	char replaceUserTilde(char *);
	int replaceEnvVar(char *);
	void addArg(char *, char *);
	void reinitializeGlobals();

	void yyerror(char *);

	int yydebug = 1;
%}

%union {
	char *str;
	char eoc;
}

%type <str> io_argument

%token <str> CMD ARG EXPANDED_FILE EXPANDED_USER OUT_RA OUT_ERR_R OUT_ERR_RA ERR_2_FILE ERR_2_OUT BUILTIN ERROR ENV_VAR
%token <eoc> EOC

%%

statement :
			  commands
			;

commands :
			  commands command							{
															if(reached_eoc == 1) {
																reinitializeGlobals();

																YYACCEPT;
															}
														}
			| /* NULL */								{
															if(reached_eoc == 1) {
																reinitializeGlobals();

																YYACCEPT;
															}
														}
			;

command :
			  CMD arguments io_redirects end_of_command	{
															checkAndAlloc();

						  									if(strlen($1) > CMD_LENGTH) {
						  										yyerror("Error: Command has too many characters.");
						  										yerrno = CMD_ERR;

						  										YYABORT;
						  									}

								  							strcpy(new_cmd.C_NAME, $1);

								  							cmdtab[num_cmds] = new_cmd;
								  							cmdtab[num_cmds].C_ARGS_PNTR[0] = cmdtab[num_cmds].C_NAME;
								  							num_cmds++;

								  							new_cmd = empty_cmd;

								  							io_in_set = io_out_set = io_err_set = num_resizes = pntr_resizes = 0;

								  							//Set the input for the next command if there was a pipe.
								  							if(io_pipe) {
								  								new_cmd.C_INPUT.io.pointer = num_cmds - 1;
																new_cmd.C_INPUT.field = C_IO_POINTER;

																io_pipe = 0;
																io_in_set = 1;
								  							}
														}
			| BUILTIN arguments EOC						{
															checkAndAlloc();

															garbage_collected = GC_TRUE;	//EOC was read.

															//No need to check the length of the command since the regex is very strict for builtins.
															//Make sure this is the only command.  If not, return an error.
															if(num_cmds > 0) {
																yyerror("Error: I/O redirection is not supported with builtin commands.");
																yerrno = BUILTIN_ERR;

						  										YYABORT;
															}

								  							strcpy(new_cmd.C_NAME, $1);
								  							new_cmd.C_ARGS_PNTR[0] = &new_cmd.C_NAME[0];

								  							cmdtab[num_cmds] = new_cmd;
								  							cmdtab[num_cmds].C_ARGS_PNTR[0] = cmdtab[num_cmds].C_NAME;
								  							num_cmds++;

								  							reached_eoc = 1;

								  							new_cmd = empty_cmd;

								  							io_in_set = io_out_set = io_err_set = num_resizes = pntr_resizes = 0;
														}
			| EOC										{
															reinitializeGlobals();

															garbage_collected = GC_TRUE;

															YYACCEPT;
														}
			;

end_of_command :
			  EOC 										{
			  												reached_eoc = 1;
			  												garbage_collected = GC_TRUE;
														}
			| '|'										{
			  												if(io_out_set == 1) {
			  													yyerror("I/O Error: Output can only be redirected once per command.");
			  													yerrno = IO_ERR;

			  													YYABORT;
			  												}
						  									
															io_pipe = 1;

															new_cmd.C_OUTPUT.io.pointer = num_cmds + 1;
															new_cmd.C_OUTPUT.field = C_IO_POINTER;
														}
			| '&'										{
															bg_mode = BG_MODE_TRUE;
														}
			;

io_redirects :
			  io_redirects io_redirect
			| /* NULL */
			;

io_redirect :
			  '<' io_argument							{
			  												if(io_in_set == 1) {
			  													yyerror("I/O Error: Input can only be redirected once per command.");
			  													yerrno = IO_ERR;

			  													YYABORT;
			  												}

															new_cmd.C_INPUT.io.file = malloc(strlen($2));
															
															strcpy(new_cmd.C_INPUT.io.file, $2);
															new_cmd.C_INPUT.field = C_IO_FILE;

															io_in_set = 1;
														}
			| '>' io_argument							{
			  												if(io_out_set == 1) {
			  													yyerror("I/O Error: Output can only be redirected once per command.");
			  													yerrno = IO_ERR;

			  													YYABORT;
			  												}

															new_cmd.C_OUTPUT.io.file = malloc(strlen($2));

															strcpy(new_cmd.C_OUTPUT.io.file, $2);
															new_cmd.C_OUTPUT.field = C_IO_FILE;

															io_out_set = 1;
														}
			| OUT_RA io_argument
			| ERR_2_FILE io_argument					{
			  												if(io_err_set == 1) {
			  													yyerror("I/O Error: Error can only be redirected once per command.");
			  													yerrno = IO_ERR;

			  													YYABORT;
			  												}

															new_cmd.C_ERR.io.file = malloc(strlen($2));

															strcpy(new_cmd.C_ERR.io.file, $2);
															new_cmd.C_ERR.field = C_IO_FILE;

															io_err_set = 1;
														}
			| ERR_2_OUT									{
			  												if(io_err_set == 1) {
			  													yyerror("I/O Error: Error can only be redirected once per command.");
			  													yerrno = IO_ERR;

			  													YYABORT;
			  												}

															new_cmd.C_ERR.io.pointer = YAS_STDOUT;
															new_cmd.C_ERR.field = C_IO_POINTER;

															io_err_set = 1;
														}
			;

arguments :
			  arguments argument
			| /* NULL */								{
															checkAndAlloc();
														}
			;

argument :
			  ARG										{
						  									checkAndAlloc();

						  									if(new_cmd.C_NARGS > 2) {
							  									int i = 0;
						  										char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS - 1];		//Pointer to the beginning of the last argument.

							  									while(last_arg[i])	i++;		//Find where the last argument ends.

																if(new_cmd.C_NARGS >= INIT_ARGS) {
																	reallocArgsPntr();
																}

							  									new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS] = &last_arg[++i];
						  									}

						  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], $1);
						  								}
			| EXPANDED_FILE								{
															checkAndAlloc();

						  									if(new_cmd.C_NARGS > 2) {
							  									int i = 0;
						  										char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS - 1];		//Pointer to the beginning of the last argument.

							  									while(last_arg[i])	i++;		//Find where the last argument ends.

																if(new_cmd.C_NARGS >= INIT_ARGS) {
																	reallocArgsPntr();
																}

							  									new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS] = &last_arg[++i];
						  									}

						  									replaceTilde($1);

						  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], argument);
														}
			| EXPANDED_USER								{
															checkAndAlloc();

						  									if(new_cmd.C_NARGS > 2) {
							  									int i = 0;
						  										char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS - 1];		//Pointer to the beginning of the last argument.

							  									while(last_arg[i])	i++;		//Find where the last argument ends.

																if(new_cmd.C_NARGS >= INIT_ARGS) {
																	reallocArgsPntr();
																}

							  									new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS] = &last_arg[++i];
						  									}

						  									if(replaceUserTilde($1) == 2) {
						  										yerrno = USER_ERR;

						  										YYABORT;
						  									}

						  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], argument);
														}
			| ENV_VAR									{
															checkAndAlloc();

						  									if(new_cmd.C_NARGS > 2) {
							  									int i = 0;
						  										char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS - 1];		//Pointer to the beginning of the last argument.

							  									while(last_arg[i])	i++;		//Find where the last argument ends.

																if(new_cmd.C_NARGS >= INIT_ARGS) {
																	reallocArgsPntr();
																}

							  									new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS] = &last_arg[++i];
						  									}

						  									if(replaceEnvVar($1)) {
						  										yyerror("Error: Environmental variable not found.");
						  										yerrno = ENV_ERR;

						  										YYABORT;
						  									}

						  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], argument);
														}
			;

io_argument :											/* IO arguments are handled slightly differently than regular arguments (they are placed in a separate field in the table). */
			  ARG										{
						  									if(strlen($1) > PATH_MAX) {
						  										yyerror("Error: Specified path too long.");
						  										yerrno = ARG_ERR;

						  										YYABORT;
						  									}

						  									$$ = $1;
						  								}
			| EXPANDED_FILE								{
						  									replaceTilde($1);

						  									if(strlen(argument) > PATH_MAX) {
						  										yyerror("Error: Specified path too long (including the tilde expansion).");
						  										yerrno = ARG_ERR;

						  										YYABORT;
							  								}

							  								$$ = argument;
														}
			| EXPANDED_USER								{
						  									if(replaceUserTilde($1) == 2) {
						  										yerrno = USER_ERR;

						  										YYABORT;
						  									}

						  									if(strlen(argument) > PATH_MAX) {
						  										yyerror("Error: Specified path too long (including the tilde expansion).");
						  										yerrno = ARG_ERR;
																
						  										YYABORT;
							  								}

							  								$$ = argument;
														}
			| ENV_VAR									{
															if(replaceEnvVar($1)) {
																yyerror("Error: Environmental variable not found.");
																yerrno = ENV_ERR;

																YYABORT;
															}

															if(strlen(argument) > PATH_MAX) {
																yyerror("Error: Specified path too long (including the expanded environmental variable).");
																yerrno = ENV_ERR;

																YYABORT;
															}

															$$ = argument;
														}
			;

%%

void reinitializeGlobals() {
	//Reinitialize all variables.
	num_resizes = 0;
	pntr_resizes = 0;
	reached_eoc = 0;
	io_in_set = 0;
	io_out_set = 0;
	io_err_set = 0;
	io_pipe = 0;

	new_cmd = empty_cmd;
}

void checkAndAlloc(void) {
	if(!new_cmd.C_ARGS) {
		new_cmd.C_ARGS = calloc(ARG_LENGTH, sizeof(char *));
	}
	
	if(!new_cmd.C_ARGS_PNTR) {
		new_cmd.C_ARGS_PNTR = calloc(INIT_ARGS, sizeof(char **));

		new_cmd.C_ARGS_PNTR[1] = &new_cmd.C_ARGS[0];
	}
}

void reallocArgs() {
	char *old_ptr = new_cmd.C_ARGS;		//Keep track of where new_cmd.C_ARGS was originally.
	num_resizes++;						//Increment number of times the array was resized.

	new_cmd.C_ARGS = (char *) realloc(new_cmd.C_ARGS, ARG_LENGTH * RESIZE_RATIO * (num_resizes + 1) * sizeof(char *));

	//If the location new_cmd.C_ARGS was pointing moved, all the pointers in C_ARGS_PNTR need to be updated.
	if(old_ptr != new_cmd.C_ARGS) {
		int i = 0, j = 0;

		new_cmd.C_ARGS_PNTR[0] = new_cmd.C_ARGS;

		while(i < new_cmd.C_NARGS) {
			for(; new_cmd.C_ARGS[j]; j++);
			new_cmd.C_ARGS_PNTR[i++] = &new_cmd.C_ARGS[++j];
		}
	}
}

void reallocArgsPntr() {
	new_cmd.C_ARGS_PNTR = (char**) realloc(new_cmd.C_ARGS_PNTR, INIT_ARGS * RESIZE_RATIO * (++pntr_resizes + 1) * sizeof(char **));
}

void replaceTilde(char *filePath) {
	char *home = getenv("HOME");

	int homeLength = 0;
	while(home[homeLength++]);

	int filePathLength = 0;
	while(filePath[filePathLength++]);

	//If the environment variable ends with a '/', it should be overwritten.
	int totalLength;
	if(home[homeLength - 1] == '/') {
		homeLength -= 1;
	}

	totalLength = homeLength + filePathLength + 1;
	
	argument = (char *) malloc(totalLength);
	strcpy(argument, home);
	strcpy(&argument[homeLength-1], &filePath[1]);		//Overwrite the NULL and possible '/' char at the end of home.  Also skip the '~' in filePath.
}

char replaceUserTilde(char *word) {
	int unameLength = 0;
	while(word[unameLength] != '/' && word[unameLength] != 0) {
		unameLength++;
	}

	char uname[unameLength];
	strncpy(uname, &word[1], unameLength - 1);		//Do not copy the tilde at the beginning of word.
	uname[unameLength - 1] = 0;

	char *filePath = &word[unameLength];

	struct passwd *user = getpwnam(uname);
	if(user == NULL) {
		yyerror("Error: User not found.");
		return 2;
	}

	char *home = user->pw_dir;

	int homeLength = 0;
	while(home[homeLength++]);

	int filePathLength = 0;
	while(filePath[filePathLength++]);

	//If the environment variable ends with a '/', it should be overwritten.
	int totalLength;
	if(home[homeLength - 1] == '/') {
		homeLength -= 1;
	}

	totalLength = homeLength + filePathLength + 1;
	
	argument = (char *) malloc(totalLength);
	strcpy(argument, home);
	strcpy(&argument[homeLength-1], filePath);		//Overwrite the NULL and possible '/' char at the end of home.
}

int replaceEnvVar(char *envVar) { /*Need to do this iteratively until no replacement has been made.*/
	char *value = getenv(envVar);
	fprintf(stderr, "%s\n", envVar);

	if(value == NULL)
		return 1;

	//Make sure this environmental variable doesn't simply point to another.  If so, keep replacing value with the value of the environmental variable.
	char *temp = NULL;
	while(temp = getenv(value)) {
		free(value);
		value = temp;
	}

	int length = 0;
	while(value[length++]);

	argument = (char *) malloc(length);
	strcpy(argument, value);

	return 0;
}

void addArg(char *dest, char *src) {
	checkAndAlloc();

	int i = 0;
	while(src[i]) {
		//If the arguments array is not long enough, we need to reallocate space to it
		int distance = &dest[i] - new_cmd.C_ARGS;
		char *old = new_cmd.C_ARGS;

		if(distance >= (ARG_LENGTH * RESIZE_RATIO * (num_resizes + 1))) {
			reallocArgs();

			if(old != new_cmd.C_ARGS) {
				dest = new_cmd.C_ARGS + distance;
			}
		}

		dest[i] = src[i];

		i++;
	}

	new_cmd.C_NARGS++;
}

void yyerror(char *err) {
	fprintf(stderr, "%s\n", err);

	reinitializeGlobals();		//After calling yyerror, YYABORT should be called so there should be no harm in reinitializing variables here.
}

// int main(void) {
// 	yyparse();

// 	int i=0;
// 	for(; i < num_cmds; i++) {
// 		printf("Command %d name: %s\n", i, cmdtab[i].C_NAME);
// 		printf("\tNumber of arguments: %d\n", cmdtab[i].C_NARGS);

// 		int j=0;
// 		for(; j < cmdtab[i].C_NARGS; j++) {
// 			printf("\t\tArg %d: %s\n", j, cmdtab[i].C_ARGS_PNTR[j]);
// 		}

// 		if(cmdtab[i].C_INPUT.field == C_IO_FILE) {
// 			printf("\tInput: %s\n", cmdtab[i].C_INPUT.io.file);
// 		} else {
// 			printf("\tInput: %d\n", cmdtab[i].C_INPUT.io.pointer);
// 		}

// 		if(cmdtab[i].C_OUTPUT.field == C_IO_FILE) {
// 			printf("\tOutput: %s\n", cmdtab[i].C_OUTPUT.io.file);
// 		} else {
// 			printf("\tOutput: %d\n", cmdtab[i].C_OUTPUT.io.pointer);
// 		}

// 		if(cmdtab[i].C_ERR.field == C_IO_FILE) {
// 			printf("\tError: %s\n", cmdtab[i].C_ERR.io.file);
// 		} else {
// 			printf("\tError: %d\n", cmdtab[i].C_ERR.io.pointer);
// 		}
// 	}

// 	printf("\tBackground: %s", bg_mode ? "Yes" : "No");

// 	return 0;
// }