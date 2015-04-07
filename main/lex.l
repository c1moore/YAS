%{
	#include <dirent.h>
	#include <fnmatch.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#include <sys/types.h>
	#include "y.tab.h"
	#include "yas.h"

	void trim(char *);
	int expandAliases(char *);
	void removeEscapes(char *, int);
	void removeEscapedQuotes(char *, int);

	char aliased = 0;			//Keep track of whether the last token read was an alias.  If so, the argument is a command.
	char *parentAlias = NULL;	//While expanding aliases, if a nested alias is equal to the original alias (parentAlias), throw an error.

	void yyerror(char *);
%}

%x PS BI AM

%%

<INITIAL>^[ \t]*alias|^[ \t]*ALIAS 									{
																		BEGIN BI;
																		yylval.str = strdup("alias");
																		builtin = BUILTIN_ALIAS;
																		return BUILTIN;
																	}

<PS>alias|ALIAS 													{
																		BEGIN BI;
																		yylval.str = strdup("alias");
																		builtin = BUILTIN_ALIAS;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*bye|^[ \t]*BYE|^[ \t]*exit|^[ \t]*EXIT|^[ \t]*close|^[ \t]*CLOSE	{
																		BEGIN BI;
																		yylval.str = strdup("bye");
																		builtin = BUILTIN_BYE;
																		return BUILTIN;
																	}

<PS>bye|BYE|exit|EXIT|close|CLOSE									{
																		BEGIN BI;
																		yylval.str = strdup("bye");
																		builtin = BUILTIN_BYE;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*cd|^[ \t]*CD 										{
																		BEGIN BI;
																		yylval.str = strdup("cd");
																		builtin = BUILTIN_CD;
																		return BUILTIN;
																	}

<PS>cd|CD 															{
																		BEGIN BI;
																		yylval.str = strdup("cd");
																		builtin = BUILTIN_CD;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*debug|^[ \t]*DEBUG									{
																		BEGIN BI;
																		yylval.str = strdup("debug");
																		builtin = BUILTIN_DEBUG;
																		return BUILTIN;
																	}

<PS>debug|DEBUG														{
																		BEGIN BI;
																		yylval.str = strdup("debug");
																		builtin = BUILTIN_DEBUG;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*printenv|^[ \t]*PRINTENV							{
																		BEGIN BI;
																		yylval.str = strdup("printenv");
																		builtin = BUILTIN_PRNTENV;
																		return BUILTIN;
																	}

<PS>printenv|PRINTENV												{
																		BEGIN BI;
																		yylval.str = strdup("printenv");
																		builtin = BUILTIN_PRNTENV;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*setenv|^[ \t]*SETENV								{
																		BEGIN BI;
																		yylval.str = strdup("setenv");
																		builtin = BUILTIN_SETENV;
																		return BUILTIN;
																	}

<PS>setenv|SETENV													{
																		BEGIN BI;
																		yylval.str = strdup("setenv");
																		builtin = BUILTIN_SETENV;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*unalias|^[ \t]*UNALIAS								{
																		BEGIN BI;
																		yylval.str = strdup("unalias");
																		builtin = BUILTIN_UNALIAS;
																		return BUILTIN;
																	}

<PS>unalias|UNALIAS													{
																		BEGIN BI;
																		yylval.str = strdup("unalias");
																		builtin = BUILTIN_UNALIAS;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*unsetenv|^[ \t]*UNSETENV							{
																		BEGIN BI;
																		yylval.str = strdup("unsetenv");
																		builtin = BUILTIN_UNENV;
																		return BUILTIN;
																	}

<PS>unsetenv|UNSETENV												{
																		BEGIN BI;
																		yylval.str = strdup("unsetenv");
																		builtin = BUILTIN_UNENV;
																		return BUILTIN;
																	}

^[ \t]*("./")?[-a-zA-Z0-9./_]+										{
																		trim(yytext);
																		int result = expandAliases(yytext);
																		if(!result) {
																			yylval.str = strdup(yytext);
																			return CMD;
																		} else if(result == -1) {
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

^[ \t]*\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|:;',.<> \t]*(\\\")*)*\"	{
																		yytext[yyleng - 1] = 0;		//Remove trailing quote.
																		trim(yytext);				//Remove whitespace before first quote
																		int result = expandAliases(&yytext[1]);
																		if(!result) {
																			yylval.str = strdup(&yytext[1]);
																			return CMD;
																		} else if(result == -1) {
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

^[ \t]*-*([-a-zA-Z0-9.:/_]+(\\[ a-zA-Z0-9<>|"\\&*?]?)*)*			{
																		trim(yytext);
																		removeEscapes(yytext, yyleng);
																		int result = expandAliases(yytext);
																		if(!result) {
																			yylval.str = strdup(yytext);
																			return CMD;
																		} else if(result == -1) {
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

<PS>("./")?[-a-zA-Z0-9./_]+											{
																		int result = expandAliases(yytext);
																		if(!result) {
																			BEGIN 0;
																			yylval.str = strdup(yytext);
																			trim(yylval.str);
																			return CMD;
																		} else if(result == -1) {
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

<PS>\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|:;',.<> \t]*(\\\")*)*\"	{
																		yytext[yyleng - 1] = 0;		//Remove trailing quote.
																		trim(yytext);				//Remove whitespace before first quote
																		int result = expandAliases(&yytext[1]);
																		if(!result) {
																			yylval.str = strdup(&yytext[1]);
																			return CMD;
																		} else if(result == -1) {
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

<PS>-*([-a-zA-Z0-9.:/_]+(\\[ a-zA-Z0-9<>|"\\&*?]?)*)*				{
																		trim(yytext);
																		removeEscapes(yytext, yyleng);
																		int result = expandAliases(yytext);
																		if(!result) {
																			yylval.str = strdup(yytext);
																			return CMD;
																		} else if(result == -1) {
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

<AM>[ \t]*("./")?[-a-zA-Z0-9./_]+									{
																		if(!aliased) {
																			BEGIN 0;
																			yyless(0);
																		} else {
																			int result = expandAliases(yytext);
																			if(!result) {
																				BEGIN 0;
																				yylval.str = strdup(yytext);
																				trim(yylval.str);

																				if(parentAlias != NULL) {
																					free(parentAlias);
																					parentAlias = NULL;
																				}
																				aliased = 0;

																				return CMD;
																			} else if(result == -1) {
																				BEGIN 0;
																				return ERROR;
																			}
																		}
																	}

<INITIAL,PS,BI>"|"													{
																		if(YY_START == BI) {
																			fprintf(stderr, ANSI_COLOR_RED "Error: I/O redirection is not supported with builtin commands.\n" ANSI_COLOR_RESET);
																			return ERROR;
																		}
																		BEGIN PS;
																		return *yytext;
																	}

<INITIAL,BI>\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|:;',.<> \t]*(\\\")*)*\"	{
																		char temp = yytext[yyleng - 1];

																		yytext[yyleng - 1] = 0;					/* Remove the trailing '"' */
																		yylval.str = strdup(&yytext[1]);		/* Don't copy the '"' */

																		yytext[yyleng - 1] = temp;
																		int argLength = yyleng - 2;

																		removeEscapedQuotes(yylval.str, argLength);

																		return ARG;
																	}
<INITIAL,BI>-*([-a-zA-Z0-9.:/_]+(\\[ a-zA-Z0-9<>|"\\&*?]?)*)*		{
																		yylval.str = strdup(yytext);

																		removeEscapes(yylval.str, yyleng);

																		return ARG;
																	}
<INITIAL,BI>([-a-zA-Z0-9.:/*?_]+(\\[ a-zA-Z0-9<>|"\\&*?]?)*)*		{
																		int matches = expandWildcards(yytext);
																		if(matches == -1) {
																			return ERROR;
																		} else if(matches == 1) {
																			fprintf(stderr, ANSI_COLOR_RED "Error: No files found that match %s\n" ANSI_COLOR_RESET, yytext);
																			return ERROR;
																		}
																	}

<INITIAL,BI>"${"(\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|;',<> \t]*(\\\")*)*\")"}"	{
																		yytext[yyleng - 2] = 0;						/* Remove the trailing '"}' */
																		int argLength = yyleng - 5;					/* New length of yylval.str */

																		removeEscapedQuotes(&yytext[3], argLength);	/* Remove escaped quotes. */

																		/* Replace/expand the environmental variable.  If there was an error, return ERROR. */
																		if(replaceEnvVar(&yytext[3]) == -1) {
																			return ERROR;
																		}
																	}
<INITIAL,BI>"${"(-*([-a-zA-Z0-9.:/_()?*`~!@#$%^&=+\]|;',<> \t]+(\\[ a-zA-Z0-9<>|"\\&?*{}}])?)*)"}"	{
																		yytext[yyleng - 1] = 0;					/* Remove the trailing '}' */
																		int argLength = yyleng - 3;				/* Length of arg as seen by replaceEnvVar */

																		removeEscapes(yylval.str, yyleng);		/* Remove escaped characters. */

																		/* Replace/expand the environmental variable.  If there wa an error, return ERROR. */
																		if(replaceEnvVar(&yytext[2]) == -1) {
																			return ERROR;
																		}
																	}

2>																	return ERR_2_FILE;

2>&1																return ERR_2_OUT;

[<>&]																return *yytext;

">>"																return OUT_RA;

">&"																return OUT_ERR_R;

">>&"																return OUT_ERR_RA;

<INITIAL,BI>~("/"[-a-zA-Z0-9./_]*)?									{
																		yylval.str = strdup(yytext);
																		return EXPANDED_FILE;
																	}

<INITIAL,BI>~[-a-zA-Z0-9_]+"/"?[-a-zA-Z0-9./_]*						{
																		yylval.str = strdup(yytext);
																		return EXPANDED_USER;
																	}

<*>[ \t]+															/* ignore white space */;

<*>.																{
																		BEGIN 0;
																		if(strcmp("|", yytext) == 0) {
																			fprintf(stderr, ANSI_COLOR_RED "Error: Builtin commands cannot be piped (I/O redirection is not supported with builtin commands).\n");
																			return ERROR;
																		}
																		fprintf(stderr, ANSI_COLOR_RED "Error: %s not recognized.\n" ANSI_COLOR_RESET, yytext);
																		return ERROR;
																	}

<INITIAL,BI>\n														{
																		BEGIN 0;
																		return EOC;
																	}

%%

/**
* Remove whitespaces from the start of a command.  Command should be a pointer to yylval.str.
*/
void trim(char *command) {
	int ws_length = 0;
	while(command[ws_length] == ' ' || command[ws_length] == '\t')
		ws_length++;

	if(ws_length != 0) {
		int i = 0;
		while(command[ws_length]) {
			command[i++] = command[ws_length++];
		}

		command[i] = 0;		//Add new null terminator.
	}
}

/**
* Check if a command is an alias.  If so handle it and return 1; otherwise, return 0.  If an
* infinite loop is detected, print error and return -1.
*/
int expandAliases(char *command) {
	if(num_aliases == 0) {
		//No aliases
		return 0;
	}

	int i;
	struct yas_alias *curr = alias_head->next;

	for(i = 0; i < num_aliases && curr; i++) {
		if(!strcmp(curr->alias, command)) {
			//Add chars from the expanded command to the input stream for Lex in reverse order (unput chars are added to the beginning of the stream).
			unput(' ');
			int len = strlen(curr->cmd) - 1;

			if(!aliased) {
				parentAlias = (char *) malloc((len + 1) * sizeof(char));
				strcpy(parentAlias, curr->alias);
			} else if(strcmp(parentAlias, curr->cmd) == 0) {
				fprintf(stderr, ANSI_COLOR_RED "Error: %s creates an infinite loop.  Fix before executing.\n", parentAlias);
				free(parentAlias);
				parentAlias = NULL;
				aliased = 0;
				return -1;
			}

			while(len >= 0) {
				unput(curr->cmd[len--]);
			}

			aliased = 1;

			break;
		}

		curr = curr->next;
	}

	return !(i == num_aliases);
}

/**
* Remove all '\' from the string.
*/
void removeEscapes(char *arg, int len) {
	int i = 0;
	for(; i < len; i++) {
		if(arg[i] == '\\') {
			int j = i;
			//Move each char back, including the NULL char.
			while(j < (len + 1)) {
				arg[j] = arg[j + 1];
				j++;
			}
		}
	}
}

/**
* In strings, '\' should be escaped only when followed by '"'.  Otherwise '\' should be ignored.
*/
void removeEscapedQuotes(char *arg, int len) {
	int i = 0;
	for(; i < (len - 1); i++) {
		if(arg[i] == '\\' && arg[i + 1] == '"') {
			int j = i;
			//Move each char back, including the NULL char.
			while(j < (len + 1)) {
				arg[j] = arg[j + 1];
				j++;
			}
		}
	}
}

/**
* Expand wildcards '*' and '?'.  Return -1 if an error occurred, return 0 if matches found,
* return 1 if no matches found.
*/
int expandWildcards(char *argument) {
	char return_value = 1;

	//If the argument contains a path, find the last '/'
	int i = 0, j = -1;
	while(argument[i]) {
		if(argument[i] == '/') {
			j = i;
		}
		i++;
	}

	char *directory = (char *) malloc(1 * sizeof(char));
	*directory = '.';

	char *pattern = (char *) malloc((strlen(argument) + 1) * sizeof(char));
	strcpy(pattern, argument);
	if(j >= 0) {
		free(directory);
		directory = (char *) malloc((argument - &argument[j] + 2) * sizeof(char));
		strncpy(directory, argument, j + 1);
		directory[j+2] = 0;

		free(pattern);
		pattern = (char *) malloc(strlen(&argument[j]) * sizeof(char));
		strcpy(pattern, &argument[j + 1]);
	}

	DIR *dir;
	if((dir = opendir(directory)) == NULL) {
		fprintf(stderr, ANSI_COLOR_RED "Error: Directory %s could not be opened.\n" ANSI_COLOR_RESET, directory);
		return -1;
	}

	struct dirent *file;
	while((file = readdir(dir)) != NULL) {
		if(fnmatch(pattern, file->d_name, FNM_PATHNAME | FNM_PERIOD) == 0) {
			//Match
			unput(' ');
			unput('"');

			int i = strlen(file->d_name) - 1;
			while(i >= 0) {
				unput(file->d_name[i--]);
			}

			unput('"');

			return_value = 0;
		}
	}

	closedir(dir);

	return return_value;
}

/**
* Replace an environmental variable and place in back in the input stream.  If the variable
* contains any ':' (colons), replace them with a ' ' (space).  Otherwise, do not modify it.
* Since environmental variables may be nested without using the syntax specified here,
* continue attempting to expand the variable until it has been fully expanded.  If an error
* occurred, return -1; otherwise return 0.
*/
int replaceEnvVar(char *envVar) {
	char *value = getenv(envVar);

	if(value == NULL) {
		fprintf(stderr, ANSI_COLOR_RED "Error: Environmental variable %s not found.\n" ANSI_COLOR_RESET, envVar);
		return -1;
	}

	//Make sure this environmental variable doesn't simply point to another.  If so, keep replacing value with the value of the environmental variable.
	char *temp = NULL;
	while(temp = getenv(value)) {
		value = temp;
	}

	unput(' ');

	int end = strlen(value) - 1;
	while(end >= 0) {
		unput(value[end--]);
	}

	return 0;
}

int yywrap() {
	return 1;
}