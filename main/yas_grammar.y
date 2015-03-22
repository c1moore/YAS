%{
	#include <sys/types.h>
	#include <pwd.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#include "../includes/yas.h"

	#define YYSTYPE char *

	static const struct cmd empty_cmd = {C_NAME_INIT, 0, 0, 0, C_IO_IN_INIT, C_IO_OUT_INIT, C_IO_ERR_INIT};
	struct cmd new_cmd = {C_NAME_INIT, 0, 0, 0, C_IO_IN_INIT, C_IO_OUT_INIT, C_IO_ERR_INIT};

	int num_resizes = 0;
	char *argument;

	void reallocArgs();
	void replaceTilde(char *, char *);
	void replaceUserTilde(char *, char *);
	void addArg(char *, char *);

	void yyerror(char *);
%}

%token CMD, ARG, EXPANDED_FILE, EXPANDED_USER, OUT_RA, OUT_ERR_R, OUT_ERR_RA, ERR_2_FILE, ERR_2_OUT

%%

statement :
			  commands
			;

commands :
			  commands command
			| commands '&'					{
												bg_mode = BG_MODE_TRUE;
											}
			| /* NULL */
			;

command :
			  CMD							{
			  									if(strlen($1) > CMD_LENGTH) {
			  										yyerror("Command has too many characters.");
			  									}

					  							strcpy(new_cmd.C_NAME, $1);
					  							new_cmd.C_NARGS = 0,
					  							new_cmd.C_ARGS[0] = '\0',
					  							new_cmd.C_ARGS_PNTR[0] = &(new_cmd.C_ARGS[0]);

					  							cmdtab[num_cmds++] = new_cmd;

					  							new_cmd = empty_cmd;
				  							}
			| CMD arguments					{
			  									if(strlen($1) > CMD_LENGTH) {
			  										yyerror("Command has too many characters.");
			  									}

					  							strcpy(new_cmd.C_NAME, $1);

					  							cmdtab[num_cmds++] = new_cmd;

					  							new_cmd = empty_cmd;
											}
			| CMD arguments io_redirects	{
			  									if(strlen($1) > CMD_LENGTH) {
			  										yyerror("Command has too many characters.");
			  									}

					  							strcpy(new_cmd.C_NAME, $1);

					  							cmdtab[num_cmds++] = new_cmd;

					  							new_cmd = empty_cmd;
											}
			| CMD io_redirects				{
			  									if(strlen($1) > CMD_LENGTH) {
			  										yyerror("Command has too many characters.");
			  									}

					  							strcpy(new_cmd.C_NAME, $1);
					  							new_cmd.C_NARGS = 0,
					  							new_cmd.C_ARGS[0] = '\0',
					  							new_cmd.C_ARGS_PNTR[0] = &(new_cmd.C_ARGS[0]);

					  							cmdtab[num_cmds++] = new_cmd;

					  							new_cmd = empty_cmd;
				  							}
			;

io_redirects :
			  io_redirects io_redirect
			;

io_redirect :
			  '|'							{
			  									/* The last command entered in cmdtab will obtain the output of this command as its input. */
			  									cmdtab[num_cmds - 1].C_INPUT.io.pointer = num_cmds;
			  									cmdtab[num_cmds - 1].C_INPUT.field = C_IO_POINTER;

			  									new_cmd.C_OUTPUT.io.pointer = num_cmds - 1;
			  									new_cmd.C_OUTPUT.field = C_IO_POINTER;
			  								}
			| '<' io_argument				{
												new_cmd.C_INPUT.io.file = malloc(strlen($2));
												
												strcpy(new_cmd.C_INPUT.io.file, $2);
												new_cmd.C_INPUT.field = C_IO_FILE;
											}
			| '>' io_argument				{
												new_cmd.C_OUTPUT.io.file = malloc(strlen($2));

												strcpy(new_cmd.C_OUTPUT.io.file, $2);
												new_cmd.C_OUTPUT.field = C_IO_FILE;
											}
			| OUT_RA io_argument
			| ERR_2_FILE io_argument		{
												new_cmd.C_ERR.io.file = malloc(strlen($2));

												strcpy(new_cmd.C_ERR.io.file, $2);
												new_cmd.C_ERR.field = C_IO_FILE;
											}
			| ERR_2_OUT						{
												new_cmd.C_ERR.io.pointer = YAS_STDOUT;
												new_cmd.C_ERR.field = C_IO_POINTER;
											}
			;

arguments :
			  arguments argument
			;

argument :
			  ARG							{
			  									int i = 0;
			  									char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS];	//Pointer to the beginning of the last argument.
			  									while(last_arg[i])	i++;								//Find where the last argument ends.

			  									new_cmd.C_ARGS_PNTR[++new_cmd.C_NARGS] = &last_arg[++i];

			  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], $1);
			  								}
			| EXPANDED_FILE					{
			  									int i = 0;
			  									char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS];	//Pointer to the beginning of the last argument.
			  									while(last_arg[i])	i++;								//Find where the last argument ends.

			  									new_cmd.C_ARGS_PNTR[++new_cmd.C_NARGS] = &last_arg[++i];

			  									replaceTilde(argument, $1);

			  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], argument);
											}
			| EXPANDED_USER					{
			  									int i = 0;
			  									char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS];	//Pointer to the beginning of the last argument.
			  									while(last_arg[i])	i++;								//Find where the last argument ends.

			  									new_cmd.C_ARGS_PNTR[++new_cmd.C_NARGS] = &last_arg[++i];

			  									replaceUserTilde(argument, $1);

			  									addArg(new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS], argument);
											}
			;

io_argument :								/* IO arguments are handled slightly differently than regular arguments (they are placed in a separate field in the table). */
			  ARG							{
			  									if(strlen($1) > PATH_MAX) {
			  										yyerror("Specified path too long.");
			  									}

			  									$$ = $1;
			  								}
			| EXPANDED_FILE					{
			  									replaceTilde(argument, $1);

			  									if(strlen(argument) > PATH_MAX) {
			  										yyerror("Specified path too long (including the tilde expansion).");
				  								}

				  								$$ = argument;
											}
			| EXPANDED_USER					{
			  									replaceTilde(argument, $1);

			  									if(strlen(argument) > PATH_MAX) {
			  										yyerror("Specified path too long (including the tilde expansion).");
				  								}

				  								$$ = argument;
											}
			;

%%

void reallocArgs() {
	char *old_ptr = new_cmd.C_ARGS;		//Keep track of where new_cmd.C_ARGS was originally.
	num_resizes++;						//Increment number of times the array was resized.

	new_cmd.C_ARGS = (char *) realloc(new_cmd.C_ARGS, ARG_LENGTH * RESIZE_RATIO * num_resizes);

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

void replaceTilde(char *dest, char *filePath) {
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
	int i = 0;
	while(src[i]) {
		//If the arguments array is not long enough, we need to reallocate space to it
		int distance = dest - new_cmd.C_ARGS;
		char *old = new_cmd.C_ARGS;

		if(distance >= (ARG_LENGTH * RESIZE_RATIO * num_resizes)) {
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