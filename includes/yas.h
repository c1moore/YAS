#ifndef _YAS_H
	#define _YAS_H

	#include "yas_limits.h"

	/**
	* Define the possible values for bg_mode.
	*/
	#define BG_MODE_TRUE	1
	#define BG_MODE_FALSE	0

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
		char C_ARGS[INIT_ARGS][ARG_LENGTH];		//Specified arguments
		union C_IO_TYPE C_INPUT;				//Input for the command
		union C_IO_TYPE C_OUTPUT;				//Output for the command
	};

	struct cmd cmdtab[CMDS_MAX];				//Table of commands

	/**
	* Specifies whether this command should run in the background.  If its value is
	* BG_MODE_TRUE, this command should run in the background.  If its value is
	* BG_MODE_FALSE, the shell should wait for the result of running this command
	* before continuing.
	*/
	char bg_mode;
#endif