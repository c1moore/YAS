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
	#define YAS_STDOUT		-2
	#define YAS_STDERR		-3

	#define C_IO_FILE		1
	#define C_IO_POINTER	2

	/**
	* Define the type to be used for C_INPUT and C_OUTPUT.  Since I/O for a command can
	* be either a filename (char *), a pointer to another command (int), or STDIN or
	* STDOUT (int); we will use a union of these types.
	*/
	union C_IO_UNION {
		int pointer;
		char *file;
	};

	struct C_IO_TYPE {
		union C_IO_UNION io;
		char field;
	};

	/**
	* Entries to cmdtab, each entry represents a command.
	*/
	struct cmd {
		char C_NAME[CMD_LENGTH];				//Command to execute
		int C_NARGS;							//Number of arguments specified
		char *C_ARGS;							//Specified arguments
		char **C_ARGS_PNTR;						//Pointer to each argument in C_ARGS.
		struct C_IO_TYPE C_INPUT;				//Input for the command
		struct C_IO_TYPE C_OUTPUT;				//Output for the command
		struct C_IO_TYPE C_ERR;					//Error for the command
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

	#define C_NAME_INIT		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	#define C_IO_IN_INIT	{YAS_STDIN, 0}
	#define C_IO_OUT_INIT	{YAS_STDOUT, 0}
	#define C_IO_ERR_INIT	{YAS_STDERR, 0}
#endif