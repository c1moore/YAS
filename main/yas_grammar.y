%{
	#include <stdlib.h>
	#include "yas.h"

	struct cmd new_cmd;
	static const struct cmd empty_cmd

	int num_resizes = 0;
%}

%token CMD, ARG, EXPANDED_FILE, OUT_RA, OUT_ERR_R, OUT_ERR_RA, ERR_2_FILE, ERR_2_OUT

%%

statement :
			  commands
			;

commands :
			  commands command
			| commands '&'			{bg_mode = BG_MODE_TRUE;}
			| /* NULL */
			;

command :
			  CMD							{
					  							strncpy(new_cmd.C_NAME, yylval, CMD_LENGTH);
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

											}
			| CMD arguments io_redirects
			| CMD io_redirects
			;

io_redirects :
			  io_redirects io_redirect
			;

io_redirect :
			  '|'
			| '<' argument
			| '>' argument
			| OUT_RA argument
			| ERR_2_FILE argument
			| ERR_2_OUT
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

			  									int j = 0;
			  									while(yylval[j]) {
			  										//If the arguments array is not long enough, we need to reallocate space to it
				  									if((last_arg - new_cmd.C_ARGS) >= (ARG_LENGTH * RESIZE_RATIO * num_resizes)) {
				  										reallocArgs();
				  									}

				  									//Replace the tilde at the beginning of yylval with the correct PATH variable.
				  								}
											}
			;

%%

void reallocArgs() {
	char *old_ptr = args;		//Keep track of where new_cmd.C_ARGS was originally.
	num_resizes++;				//Increment number of times the array was resized.

	realloc(new_cmd.C_ARGS, ARG_LENGTH * RESIZE_RATIO * num_resizes);

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