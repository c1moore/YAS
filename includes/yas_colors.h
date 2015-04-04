#ifndef _YAS_COLORS
	#define _YAS_COLORS
	
	/**
	* Escape codes to add color to terminal.  These only in terminals that support ANSI escape
	* sequences.  Otherwise, they will be ignored.
	*/
	#define ANSI_COLOR_RED		"\x1b[31m"
	#define ANSI_COLOR_GREEN	"\x1b[32m"
	#define ANSI_COLOR_YELLOW	"\x1b[33m"
	#define ANSI_COLOR_BLUE		"\x1b[34m"
	#define ANSI_COLOR_MAGENTA	"\x1b[35m"
	#define ANSI_COLOR_CYAN		"\x1b[36m"
	#define ANSI_COLOR_RESET	"\x1b[0m"
#endif