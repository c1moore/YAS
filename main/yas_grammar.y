%{
	#include <stdlib.h>
	#include "yas.h"
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
			  CMD					{
			  							struct cmd new_cmd;
			  							new_cmd.C_NAME
			  							new_cmd.C_NARGS = 0,
			  							new_cmd.C_ARGS[0] = '\0',
			  							new_cmd.C_ARGS_PNTR[0] = &(new_cmd.C_ARGS[0]);
			  							new_cmd.C_INPUT = YAS_STDIN;
			  							new_cmd.C_OUPUT = YAS_STDOUT;
			  							new_cmd.C_ERR = YAS_STDERR;

			  							cmdtab[num_cmds++] = new_cmd;
			  						}
			| CMD arguments
			| CMD arguments io_redirects
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
			  ARG
			| EXPANDED_FILE
			;