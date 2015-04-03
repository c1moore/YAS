#ifndef _YAS_H
	#define _YAS_H

	#include "yas_limits.h"
	#include "yas_structures.h"
	#include "yas_errors.h"
	#include "yas_builtin.h"

	/**
	* Define the possible values for bg_mode.
	*/
	#define BG_MODE_TRUE	1
	#define BG_MODE_FALSE	0

	/**
	* Define the possible values for builtin.
	*/
	#define BUILTIN_FALSE	0
	#define BUILTIN_ALIAS	1
	#define BUILTIN_BYE		2
	#define BUILTIN_CD		3
	#define BUILTIN_PRNTENV	4
	#define BUILTIN_SETENV	5
	#define BUILTIN_UNALIAS	6
	#define BUILTIN_UNENV	7

	/**
	* Define the possible values for garbage_collected.
	*/
	#define GC_TRUE			1
	#define GC_FALSE		2

	/**
	* The values to enter for C_INPUT and C_OUTPUT when standard input,
	* standard output, and standard error should be used.
	*/
	#define YAS_STDIN		-1
	#define YAS_STDOUT		-2
	#define YAS_STDERR		-3

	/**
	* Specifies whether this command should run in the background.  If its value is
	* BG_MODE_TRUE, this command should run in the background.  If its value is
	* BG_MODE_FALSE, the shell should wait for the result of running this command
	* before continuing.
	*/
	extern char bg_mode;

	/**
	* Specifies if the given command is a builtin command.
	*/
	extern char builtin;

	/**
	* Keep a record of where the error occurred.  If EOC (\n) was reached, Lex read
	* all the tokens for the last command and this should be set to GC_TRUE.
	* Otherwise, tokens remain and need to be cleaned before the next command is
	* read.
	*/
	extern char garbage_collected;

	/**
	* The error code that caused YACC to abort (call YYABORT).  Should be set to 0
	* when there is no error.
	*/
	extern int yerrno;

	#define C_NAME_INIT		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	#define C_IO_IN_INIT	{YAS_STDIN, C_IO_POINTER, C_IO_NA}
	#define C_IO_OUT_INIT	{YAS_STDOUT, C_IO_POINTER, C_IO_NA}
	#define C_IO_ERR_INIT	{YAS_STDERR, C_IO_POINTER, C_IO_NA}

	#define YAS_BANNER		"Welcome to YAS!\n"
#endif