%{
	#include <sys/types.h>
	#include <pwd.h>
	#include <stdlib.h>
	#include "yas.h"

	struct cmd new_cmd;
	static const struct cmd empty_cmd

	int num_resizes = 0;
	char io_in_set = 0, io_out_set = 0, io_err_set = 0;
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
			  									int length = 0;
			  									while(yylval[length])	length++;

			  									if(length > CMD_LENGTH) {
			  										yyerror("Command has too many characters.");
			  									}

					  							strcpy(new_cmd.C_NAME, yylval);
					  							new_cmd.C_NARGS = 0,
					  							new_cmd.C_ARGS[0] = '\0',
					  							new_cmd.C_ARGS_PNTR[0] = &(new_cmd.C_ARGS[0]);
					  							new_cmd.C_INPUT = YAS_STDIN;
					  							new_cmd.C_OUPUT = YAS_STDOUT;
					  							new_cmd.C_ERR = YAS_STDERR;

					  							cmdtab[num_cmds++] = new_cmd;

					  							new_cmd = empty_cmd;
				  							}
			| CMD arguments					{
			  									int length = 0;
			  									while(yylval[length])	length++;

			  									if(length > CMD_LENGTH) {
			  										yyerror("Command has too many characters.");
			  									}

					  							strcpy(new_cmd.C_NAME, yylval);
					  							new_cmd.C_INPUT = YAS_STDIN;
					  							new_cmd.C_OUPUT = YAS_STDOUT;
					  							new_cmd.C_ERR = YAS_STDERR;

					  							cmdtab[num_cmds++] = new_cmd;

					  							new_cmd = empty_cmd;
											}
			| CMD arguments io_redirects	{
			  									int length = 0;
			  									while(yylval[length])	length++;

			  									if(length > CMD_LENGTH) {
			  										yyerror("Command has too many characters.");
			  									}

					  							strcpy(new_cmd.C_NAME, yylval);

					  							if(!io_in_set)
					  								new_cmd.C_INPUT = YAS_STDIN;

					  							if(!io_out_set)
					  								new_cmd.C_OUPUT = YAS_STDOUT;

					  							if(!io_err_set)
					  								new_cmd.C_ERR = YAS_STDERR;

					  							cmdtab[num_cmds++] = new_cmd;

					  							new_cmd = empty_cmd;
											}
			| CMD io_redirects				{
			  									int length = 0;
			  									while(yylval[length])	length++;

			  									if(length > CMD_LENGTH) {
			  										yyerror("Command has too many characters.");
			  									}

					  							strcpy(new_cmd.C_NAME, yylval);
					  							new_cmd.C_NARGS = 0,
					  							new_cmd.C_ARGS[0] = '\0',
					  							new_cmd.C_ARGS_PNTR[0] = &(new_cmd.C_ARGS[0]);

					  							if(!io_in_set)
					  								new_cmd.C_INPUT = YAS_STDIN;

					  							if(!io_out_set)
					  								new_cmd.C_OUPUT = YAS_STDOUT;

					  							if(!io_err_set)
					  								new_cmd.C_ERR = YAS_STDERR;

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
			  									cmdtab[num_cmds - 1].C_INPUT = num_cmds;
			  									new_cmd.C_OUTPUT = num_cmds - 1;
			  								}
			| '<' io_argument				{
												io_in_set = 1;

												strcpy(new_cmd.C_INPUT, $2);
											}
			| '>' io_argument				{
												io_out_set = 1;

												strcpy(new_cmd.C_OUTPUT, $2);
											}
			| OUT_RA io_argument
			| ERR_2_FILE io_argument		{
												io_err_set = 1;

												strcpy(new_cmd.C_ERR, $2);
											}
			| ERR_2_OUT						{
												io_err_set = 1;

												new_cmd.C_ERR = YAS_STDOUT;
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

			  									int j = 0;
			  									while(yylval[j]) {
			  										//If the arguments array is not long enough, we need to reallocate space to it
				  									if((last_arg - new_cmd.C_ARGS) >= (ARG_LENGTH * RESIZE_RATIO * num_resizes)) {
				  										reallocArgs();
				  									}

				  									last_arg[i++] = yylval[j++];
				  								}
			  								}
			| EXPANDED_FILE					{
			  									int i = 0;
			  									char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS];	//Pointer to the beginning of the last argument.
			  									while(last_arg[i])	i++;								//Find where the last argument ends.

			  									new_cmd.C_ARGS_PNTR[++new_cmd.C_NARGS] = &last_arg[++i];

			  									char *argument;
			  									replaceTilde(argument, yylval);

			  									int j = 0;
			  									while(argument[j]) {
			  										//If the arguments array is not long enough, we need to reallocate space to it
				  									if((last_arg - new_cmd.C_ARGS) >= (ARG_LENGTH * RESIZE_RATIO * num_resizes)) {
				  										reallocArgs();
				  									}

				  									last_arg[i++] = argument[j++];
				  								}
											}
			| EXPANDED_USER_FILE			{
			  									int i = 0;
			  									char *last_arg = new_cmd.C_ARGS_PNTR[new_cmd.C_NARGS];	//Pointer to the beginning of the last argument.
			  									while(last_arg[i])	i++;								//Find where the last argument ends.

			  									new_cmd.C_ARGS_PNTR[++new_cmd.C_NARGS] = &last_arg[++i];

			  									char *argument;
			  									replaceUserTilde(argument, yylval);

			  									int j = 0;
			  									while(argument[j]) {
			  										//If the arguments array is not long enough, we need to reallocate space to it
				  									if((last_arg - new_cmd.C_ARGS) >= (ARG_LENGTH * RESIZE_RATIO * num_resizes)) {
				  										reallocArgs();
				  									}

				  									last_arg[i++] = argument[j++];
				  								}
											}
			;

io_argument :								/* IO arguments are handled slightly differently than regular arguments (they are placed in a separate field in the table). */
			  ARG							{
			  									int length = 0;
			  									while(yylval[length])	length++;								//Find where the last argument ends.

			  									if(length > PATH_MAX) {
			  										yyerror("Specified path too long.  Do not use more than " + PATH_MAX + " characters.");
			  									}

			  									$$ = $1;
			  								}
			| EXPANDED_FILE					{
			  									char *argument;
			  									replaceTilde(argument, yylval);

			  									int length = 0;
			  									while(argument[length)	length++;

			  									if(length > PATH_MAX) {
			  										yyerror("Specified path too long.  Do not use more than " + PATH_MAX + " characters (including the expanded tilde).")
				  								}

				  								$$ = $1;
											}
			| EXPANDED_USER_FILE			{
			  									char *argument;
			  									replaceTilde(argument, yylval);

			  									int length = 0;
			  									while(argument[length)	length++;

			  									if(length > PATH_MAX) {
			  										yyerror("Specified path too long.  Do not use more than " + PATH_MAX + " characters (including the expanded tilde).")
				  								}

				  								$$ = $1;
											}
			;

%%

void reallocArgs() {
	char *old_ptr = args;		//Keep track of where new_cmd.C_ARGS was originally.
	num_resizes++;				//Increment number of times the array was resized.

	new_cmd.CARGS = (char *) realloc(new_cmd.C_ARGS, ARG_LENGTH * RESIZE_RATIO * num_resizes);

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
	char *home = getEnv("HOME");

	int homeLength = sizeof(home)/sizeof(home[0]);

	int totalLength;
	if(home[homeLength - 2] == '/') {
		homeLength -= 1;
		totalLength = homeLength + (sizeof(filePath)/sizeof(filePath[0]) - 1);
	} else {
		totalLength = homeLength + (sizeof(filePath)/sizeof(filePath[0]) - 1);
	}
	
	dest = (char *) malloc(totalLength);
	strcpy(newPath, home);
	strcpy(&newPath[homeLength-1], &filePath[1]);
}

void replaceUserTilde(char *dest, char *word) {
	int unameLength = 0;
	while(word[unameLength] != '/' || word[unameLength] != 0)
		unameLength++;

	char uname[unameLength + 1];
	strncpy(uname, word, unameLength);
	uname[unameLength] = 0;

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
	strcpy(newPath, home);
	strcpy(&newPath[homeLength-1], &filePath[1]);
}