#ifndef _YAS_STRUCT
	#define _YAS_STRUCT

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
		char field;				//Specify which field of the union is used.
		char concat;			//Concatenate I/O in file specified?  Ignored when field is not C_IO_FILE.
	};

	/**
	* Define possible values for C_IO_TYPE.field.
	*/
	#define C_IO_FILE		1
	#define C_IO_POINTER	2

	/**
	* Define possible values for C_IO_TYPE.concat
	*/
	#define C_IO_OW			0	//Overwrite contents of file
	#define C_IO_CONCAT		1	//Append result to end of file

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

	int num_cmds;								//Number of commands in the command table.

	/**
	* Structure for entries in alias linked list, each entry represents an alias.
	*/
	struct yas_alias {
		char *alias;
		char *cmd;
		struct yas_alias *next;
	};

	struct yas_alias *alias_head;				//Pointer to head of alias linked list.

	int num_aliases;							//Number of defined aliases

#endif