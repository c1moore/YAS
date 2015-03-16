#ifndef _YAS_LIMITS_H
	#define _YAS_LIMITS_H

	/**
	* Find the maximum path length for this system.  If there is no maximum path length
	* set PATH_MAX to 4096, which seems to be a popular value for PATH_MAX on various
	* systems.
	*/
	#include "limits.h"
	#ifndef PATH_MAX	//Some systems do not define a PATH_MAX variable.  Define one if this is the case.
		#define PATH_MAX	4096
	#endif

	/**
	* Define the initial number of args accepted in C_ARGS.  If more args are specified
	* than INIT_ARGS, realloc can be used to enlarge the size of the C_ARGS array by the
	* current size times RESIZE_RATIO.
	*/
	#define INIT_ARGS		10
	#define RESIZE_RATIO 	2

	/**
	* Define the initial size of the C_ARGS.  This size is equal to the initial number of
	* arguments, INIT_ARGS, times a constant.  This constant is our prediction the length of
	* a typical argument.
	*/
	#define ARG_LENGTH		INIT_ARGS * 5

	/**
	* Define the maximum length of a command, CMD_LENGTH, and the maximum number of
	* commands allowed to be piped together, CMDS_MAX.
	*/
	#define CMD_LENGTH		50
	#define CMDS_MAX		50
#endif