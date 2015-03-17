#ifndef _YAS_H
	#define _YAS_H

	#include "yas_limits.h"

	/**
	* Define the possible values for bg_mode.
	*/
	#define BG_MODE_TRUE	1
	#define BG_MODE_FALSE	0

	/**
	* The values to enter for C_INPUT and C_OUTPUT when standard input,
	* standard output, and standard error should be used.
	*/
	#define YAS_STDIN		-1
	#define YAS_STOUT		-2
	#define YAS_STDERR		-3

	/**
	* Define the type to be used for C_INPUT and C_OUTPUT.  Since I/O for a command can
	* be either a filename (char *), a pointer to another command (int), or STDIN or
	* STDOUT (int); we will use a union of these types.
	*/
	union C_IO_TYPE {
		char file[PATH_MAX];
		int pointer;
	};

	/**
	* Entries to cmdtab, each entry represents a command.
	*/
	struct cmd {
		char C_NAME[CMD_LENGTH];				//Command to execute
		int C_NARGS;							//Number of arguments specified
		char C_ARGS[ARG_LENGTH];				//Specified arguments
		char *C_ARGS_PNTR[INIT_ARGS];			//Pointer to each argument in C_ARGS.
		union C_IO_TYPE C_INPUT;				//Input for the command
		union C_IO_TYPE C_OUTPUT;				//Output for the command
		union C_IO_TYPE C_ERR;					//Error for the command
	};

	struct cmd cmdtab[CMDS_MAX];				//Table of commands

	/**
	* Number of commands in the command table.
	*/
	int num_cmds = 0;

	/**
	* Specifies whether this command should run in the background.  If its value is
	* BG_MODE_TRUE, this command should run in the background.  If its value is
	* BG_MODE_FALSE, the shell should wait for the result of running this command
	* before continuing.
	*/
	char bg_mode;
#endif