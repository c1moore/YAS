#ifndef _YAS_ERRORS
	#define _YAS_ERRORS

	/**
	* Define errors codes used by YAS
	*/

	#define CMD_ERR		1		//Errors related to structure or length of command
	#define IO_ERR		2		//Errors related to I/O redirection
	#define USER_ERR	3		//Errors related to finding a user
	#define ENV_ERR		4		//Errors related to environmental variables
	#define YAS_ERR		5		//Errors related to general structure or execution of command
	#define ARG_ERR		6		//Errors related to arguments
	#define BUILTIN_ERR	7		//Errors related to builtins (attempting redirection, background execution, etc.)

#endif