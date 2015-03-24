%{
	#include <sys/types.h>
	#include <pwd.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#include "../includes/yas.h"

	static const struct cmd empty_cmd = {C_NAME_INIT, 0, 0, 0, C_IO_IN_INIT, C_IO_OUT_INIT, C_IO_ERR_INIT};
	struct cmd new_cmd = {C_NAME_INIT, 0, 0, 0, C_IO_IN_INIT, C_IO_OUT_INIT, C_IO_ERR_INIT};

	int num_resizes = 0, pntr_resizes = 0;								//Keep track of the number of times the C_ARGS and C_ARGS_PNTR has been resized.
	char *argument;														//Used for tilde expansion of arguments.
	char io_in_set = 0, io_out_set = 0, io_err_set = 0, io_pipe = 0;	//Determine if I/O has already been set.
	char reached_eoc = 0;												//Determine if '\n' has been reached (should exit if reached_eoc == 1).

	void checkAndAlloc();
	void reallocArgs();
	void replaceTilde(char *, char *);
	void replaceUserTilde(char *, char *);
	void addArg(char *, char *);

	void yyerror(char *);

	int yydebug = 1;
%}

%union {
	char *str;
	char eoc;
}

%type <str> io_argument

%token <str> CMD ARG EXPANDED_FILE EXPANDED_USER OUT_RA OUT_ERR_R OUT_ERR_RA ERR_2_FILE ERR_2_OUT
%token <eoc> EOC

%%

statement :
			  commands
			;

commands :
			  commands command							{
															fprintf(stderr, "%s\n", "Exiting");
															fflush(stderr);
															if(reached_eoc == 1) {
																return 0;
															}
														}
			| /* NULL */								{
															fprintf(stderr, "%s\n", "Exiting");
															fflush(stderr);
															if(reached_eoc == 1) {
																return 0;
															}
														}
			;

command :
			  CMD end_of_command						{
															fprintf(stderr, "%s%s\n", "Found a command. ", $1);
															fflush(stderr);
															checkAndAlloc();

						  									if(strlen($1) > CMD_LENGTH) {
						  										yyerror("Command has too many characters.");
						  									}

								  							strcpy(new_cmd.C_NAME, $1);
								  							new_cmd.C_NARGS = 0,
								  							new_cmd.C_ARGS[0] = '\0',
								  							new_cmd.C_ARGS_PNTR[0] = &(new_cmd.C_ARGS[0]);

								  							cmdtab[num_cmds++] = new_cmd;

								  							new_cmd = empty_cmd;

								  							io_in_set = io_out_set = io_err_set = num_resizes = pntr_resizes = 0;

								  							//Set the input for the next command if there was a pipe.
								  							if(io_pipe) {
								  								new_cmd.C_INPUT.io.pointer = num_cmds + 1;
																new_cmd.C_INPUT.field = C_IO_POINTER;

																io_pipe = 0;
																io_in_set = 1;
								  							}
							  							}
			| CMD arguments io_redirects end_of_command	{
															fprintf(stderr, "%s%s\n", "Found a command with arguments and I/O redirects. ", $1);
															fflush(stderr);
						  									if(strlen($1) > CMD_LENGTH) {
						  										yyerror("Command has too many characters.");
						  									}

								  							strcpy(new_cmd.C_NAME, $1);

								  							cmdtab[num_cmds++] = new_cmd;

								  							new_cmd = empty_cmd;

								  							io_in_set = io_out_set = io_err_set = num_resizes = pntr_resizes = 0;

								  							//Set the input for the next command if there was a pipe.
								  							if(io_pipe) {
								  								new_cmd.C_INPUT.io.pointer = num_cmds + 1;
																new_cmd.C_INPUT.field = C_IO_POINTER;

																io_pipe = 0;
																io_in_set = 1;
								  							}
														}
			;

end_of_command :
			  EOC 										{
			  												reached_eoc = 1;
														}
			| '|'										{
			  												if(io_out_set == 1) {
			  													yyerror("I/O Error: Output can only be redirected once per command.");
			  												}

															fprintf(stderr, "%s\n", "Found a pipe (|).");
															fflush(stderr);
						  									
															io_pipe = 1;

															new_cmd.C_OUTPUT.io.pointer = num_cmds + 1;
															new_cmd.C_OUTPUT.field = C_IO_POINTER;
						  									/*/* The last command entered in cmdtab will obtain the output of this command as its input.
						  									cmdtab[num_cmds - 1].C_INPUT.io.pointer = num_cmds;
						  									cmdtab[num_cmds - 1].C_INPUT.field = C_IO_POINTER;

						  									new_cmd.C_OUTPUT.io.pointer = num_cmds - 1;
						  									new_cmd.C_OUTPUT.field = C_IO_POINTER;*/
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
			  												}

															new_cmd.C_INPUT.io.file = malloc(strlen($2));
															
															strcpy(new_cmd.C_INPUT.io.file, $2);
															new_cmd.C_INPUT.field = C_IO_FILE;
														}
			| '>' io_argument							{
			  												if(io_in_set == 1) {
			  													yyerror("I/O Error: Out can only be redirected once per command.");
			  												}

															new_cmd.C_OUTPUT.io.file = malloc(strlen($2));

															strcpy(new_cmd.C_OUTPUT.io.file, $2);
															new_cmd.C_OUTPUT.field = C_IO_FILE;
														}
			| OUT_RA io_argument
			| ERR_2_FILE io_argument					{
			  												if(io_in_set == 1) {
			  													yyerror("I/O Error: Error can only be redirected once per command.");
			  												}

															new_cmd.C_ERR.io.file = malloc(strlen($2));

															strcpy(new_cmd.C_ERR.io.file, $2);
															new_cmd.C_ERR.field = C_IO_FILE;
														}
			| ERR_2_OUT									{
			  												if(io_in_set == 1) {
			  													yyerror("I/O Error: Error can only be redirected once per command.");
			  												}

															new_cmd.C_ERR.io.pointer = YAS_STDOUT;
															new_cmd.C_ERR.field = C_IO_POINTER;
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
															fprintf(stderr, "%s\n", "Found an ARG.");
															fflush(stderr);
						  									checkAndAlloc();

															fprintf(stderr, "%s\n", "Looking for last arg.");
															fflush(stderr);

						  									int i = 0;
						  									char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS];	//Pointer to the beginning of the last argument.
						  									while(last_arg[i])	i++;								//Find where the last argument ends.

															fprintf(stderr, "%s\n", "Adding pointer to arg.");
															fflush(stderr);

															if(++new_cmd.C_NARGS >= INIT_ARGS) {
																reallocArgsPntr();
															}

						  									new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS] = &last_arg[++i];

															fprintf(stderr, "%s\n", "Adding arg.");
															fflush(stderr);

						  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], $1);
						  								}
			| EXPANDED_FILE								{
															fprintf(stderr, "%s\n", "Found an EXPANDED_FILE.");
															fflush(stderr);
															checkAndAlloc();

						  									int i = 0;
						  									char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS];	//Pointer to the beginning of the last argument.
						  									while(last_arg[i])	i++;								//Find where the last argument ends.

															if(++new_cmd.C_NARGS >= INIT_ARGS) {
																reallocArgsPntr();
															}

						  									new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS] = &last_arg[++i];

						  									replaceTilde(argument, $1);

						  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], argument);
														}
			| EXPANDED_USER								{
															fprintf(stderr, "%s\n", "Found an EXPANDED_USER.");
															fflush(stderr);
															checkAndAlloc();

						  									int i = 0;
						  									char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS];	//Pointer to the beginning of the last argument.
						  									while(last_arg[i])	i++;								//Find where the last argument ends.

															if(++new_cmd.C_NARGS >= INIT_ARGS) {
																reallocArgsPntr();
															}

						  									new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS] = &last_arg[++i];

						  									replaceUserTilde(argument, $1);

						  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], argument);
														}
			;

io_argument :											/* IO arguments are handled slightly differently than regular arguments (they are placed in a separate field in the table). */
			  ARG										{
															fprintf(stderr, "%s\n", "Found an IO ARG.");
															fflush(stderr);
						  									if(strlen($1) > PATH_MAX) {
						  										yyerror("Specified path too long.");
						  									}

						  									$$ = $1;
						  								}
			| EXPANDED_FILE								{
															fprintf(stderr, "%s\n", "Found an IO EXPANDED_FILE.");
															fflush(stderr);
						  									replaceTilde(argument, $1);

						  									if(strlen(argument) > PATH_MAX) {
						  										yyerror("Specified path too long (including the tilde expansion).");
							  								}

							  								$$ = argument;
														}
			| EXPANDED_USER								{
															fprintf(stderr, "%s\n", "Found an IO EXPANDED_USER.");
															fflush(stderr);
						  									replaceTilde(argument, $1);

						  									if(strlen(argument) > PATH_MAX) {
						  										yyerror("Specified path too long (including the tilde expansion).");
							  								}

							  								$$ = argument;
														}
			;

%%

void checkAndAlloc(void) {
	fprintf(stderr, "%s\n", "Checking argument array and allocating space if necessary.");
	fflush(stderr);
	if(!new_cmd.C_ARGS) {
		new_cmd.C_ARGS = calloc(ARG_LENGTH, sizeof(char *));
	}
	
	if(!new_cmd.C_ARGS_PNTR) {
		new_cmd.C_ARGS_PNTR = calloc(INIT_ARGS, sizeof(char **));

		new_cmd.C_ARGS_PNTR[0] = &new_cmd.C_ARGS[0];
	}
}

void reallocArgs() {
	fprintf(stderr, "%s\n", "Reallocating space to arguments");
	fflush(stderr);
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

void replaceTilde(char *dest, char *filePath) {
	fprintf(stderr, "%s\n", "Replacing a tilde.");
	fflush(stderr);
	char *home = getenv("HOME");

	int homeLength = sizeof(home)/sizeof(home[0]);

	int totalLength;
	if(home[homeLength - 2] == '/') {
		homeLength -= 1;
		totalLength = homeLength + (sizeof(filePath)/sizeof(filePath[0]) - 1);
	} else {
		totalLength = homeLength + (sizeof(filePath)/sizeof(filePath[0]) - 1);
	}
	
	dest = (char *) malloc(totalLength);
	strcpy(dest, home);
	strcpy(&dest[homeLength-1], &filePath[1]);
}

void replaceUserTilde(char *dest, char *word) {
	fprintf(stderr, "%s\n", "Replacing a user tilde.");
	fflush(stderr);
	int unameLength = 0;
	while(word[unameLength] != '/' || word[unameLength] != 0)
		unameLength++;

	char uname[unameLength + 1];
	strncpy(uname, word, unameLength);
	uname[unameLength] = 0;

	char *filePath = &word[unameLength];

	struct passwd *user = getpwnam(uname);
	if(user == NULL) {
		yyerror("User not found.");
	}

	char *home = user->pw_dir;

	int homeLength = sizeof(home)/sizeof(home[0]);

	int totalLength;
	if(home[homeLength - 2] == '/') {
		homeLength -= 1;
		totalLength = homeLength + (sizeof(filePath)/sizeof(filePath[0]) - 1);
	} else {
		totalLength = homeLength + (sizeof(filePath)/sizeof(filePath[0]) - 1);
	}
	
	dest = (char *) malloc(totalLength);
	strcpy(dest, home);
	strcpy(&dest[homeLength-1], &filePath[1]);
}

void addArg(char *dest, char *src) {
	fprintf(stderr, "%s\n", "Adding an argument.");
	fflush(stderr);
	checkAndAlloc();

	int i = 0;
	while(src[i]) {
		//If the arguments array is not long enough, we need to reallocate space to it
		int distance = dest - new_cmd.C_ARGS;
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
}

void yyerror(char *err) {
	fprintf(stderr, "%s\n", err);
}

int main(void) {
	fprintf(stderr, "%s\n", "Beginning...");
	fflush(stderr);
	yyparse();
	fprintf(stderr, "%s\n", "Printing...");
	fflush(stderr);
	fprintf(stderr, "%d\n", num_cmds);
	fflush(stderr);

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

	return 0;
}