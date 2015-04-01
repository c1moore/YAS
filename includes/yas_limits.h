#ifndef _YAS_LIMITS_H
	#define _YAS_LIMITS_H

	/**
	* Find the maximum path length for this system.  If there is no maximum path length
	* set PATH_MAX to 4096, which seems to be a popular value for PATH_MAX on various
	* systems.  Also determine the maximum host name length (HOST_NAME_MAX).  Since
	* some systems do not define this macro, use 255 which is guaranteed to be the max
	* length by SUSv2.
	*/
	#include "limits.h"
	#ifndef PATH_MAX	//Some systems do not define a PATH_MAX variable.  Define one if this is the case.
		#define PATH_MAX	4096
	#endif
	#ifndef HOST_NAME_MAX
		#define HOST_NAME_MAX 255
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
	* arguments, INIT_ARGS, times a constant, AVG_ARG.  This constant is our prediction
	* of the length of the average argument.
	*/
	#define AVG_ARG			5
	#define ARG_LENGTH		INIT_ARGS * AVG_ARG

	/**
	* Define the maximum length of a command, CMD_LENGTH, and the maximum number of
	* commands allowed to be piped together, CMDS_MAX.
	*/
	#define CMD_LENGTH		50
	#define CMDS_MAX		50

	/**
	* Define the total number of loops we will go through until we print an error message
	* when expanding aliases/environmental variables.
	*/
	#define ALIAS_THRESHOLD	50
#endif