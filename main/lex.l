%{
	#include <dirent.h>
	#include <fnmatch.h>
	#include <pwd.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#include <sys/types.h>
	#include "y.tab.h"
	#include "yas.h"

	void trim(char *);
	int expandAliases(char *);
	int expandFileName(char *, int);
	int expandUserFileName(char *, int);
	void removeEscapes(char *, int);
	void removeEscapedQuotes(char *, int);

	char aliased = 0;			//Keep track of whether the last token read was an alias.  If so, the argument is a command.
	char *parentAlias = NULL;	//While expanding aliases, if a nested alias is equal to the original alias (parentAlias), throw an error.
	char errsExist = 0;			//Keep track of whether errors exist.

	void yyerror(char *);
	char *replaceTilde(char *, char *);
	char *replaceUserTilde(char *, char *);
%}

%x PS BI AM ERR

%%

<INITIAL>^[ \t]*alias|^[ \t]*ALIAS 									{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("alias");
																		builtin = BUILTIN_ALIAS;
																		return BUILTIN;
																	}

<PS>alias|ALIAS 													{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("alias");
																		builtin = BUILTIN_ALIAS;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*bye|^[ \t]*BYE|^[ \t]*exit|^[ \t]*EXIT|^[ \t]*close|^[ \t]*CLOSE	{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("bye");
																		builtin = BUILTIN_BYE;
																		return BUILTIN;
																	}

<PS,AM>bye|BYE|exit|EXIT|close|CLOSE									{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("bye");
																		builtin = BUILTIN_BYE;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*cd|^[ \t]*CD 										{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("cd");
																		builtin = BUILTIN_CD;
																		return BUILTIN;
																	}

<PS,AM>cd|CD 															{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("cd");
																		builtin = BUILTIN_CD;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*debug|^[ \t]*DEBUG									{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("debug");
																		builtin = BUILTIN_DEBUG;
																		return BUILTIN;
																	}

<PS,AM>debug|DEBUG														{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("debug");
																		builtin = BUILTIN_DEBUG;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*printenv|^[ \t]*PRINTENV							{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("printenv");
																		builtin = BUILTIN_PRNTENV;
																		return BUILTIN;
																	}

<PS,AM>printenv|PRINTENV												{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("printenv");
																		builtin = BUILTIN_PRNTENV;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*setenv|^[ \t]*SETENV								{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("setenv");
																		builtin = BUILTIN_SETENV;
																		return BUILTIN;
																	}

<PS,AM>setenv|SETENV													{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("setenv");
																		builtin = BUILTIN_SETENV;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*unalias|^[ \t]*UNALIAS								{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("unalias");
																		builtin = BUILTIN_UNALIAS;
																		return BUILTIN;
																	}

<PS,AM>unalias|UNALIAS													{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("unalias");
																		builtin = BUILTIN_UNALIAS;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*unsetenv|^[ \t]*UNSETENV							{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("unsetenv");
																		builtin = BUILTIN_UNENV;
																		return BUILTIN;
																	}

<PS,AM>unsetenv|UNSETENV												{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("unsetenv");
																		builtin = BUILTIN_UNENV;
																		return BUILTIN;
																	}

<INITIAL>^[ \t]*help												{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("help");
																		builtin = BUILTIN_HELP;
																		return BUILTIN;
																	}

<PS,AM>help															{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN BI;
																		yylval.str = strdup("help");
																		builtin = BUILTIN_HELP;
																		return BUILTIN;
																	}

^[ \t]*("./")?[-a-zA-Z0-9./_]+										{
																		if(errsExist) {
																			return ERROR;
																		}
																		trim(yytext);
																		int result = expandAliases(yytext);
																		if(!result) {
																			yylval.str = strdup(yytext);
																			return CMD;
																		} else if(result == -1) {
																			errsExist = 1;
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

^[ \t]*\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|:;',.<> \t]*(\\\")*)*\"	{
																		if(errsExist) {
																			return ERROR;
																		}
																		yytext[yyleng - 1] = 0;		//Remove trailing quote.
																		trim(yytext);				//Remove whitespace before first quote
																		int result = expandAliases(&yytext[1]);
																		if(!result) {
																			yylval.str = strdup(&yytext[1]);
																			return CMD;
																		} else if(result == -1) {
																			errsExist = 1;
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

^[ \t]*-*([-a-zA-Z0-9.:/_]+(\\[ a-zA-Z0-9<>|"\\&*?]?)*)*			{
																		if(errsExist) {
																			return ERROR;
																		}
																		trim(yytext);
																		removeEscapes(yytext, yyleng);
																		int result = expandAliases(yytext);
																		if(!result) {
																			yylval.str = strdup(yytext);
																			return CMD;
																		} else if(result == -1) {
																			errsExist = 1;
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

<PS>("./")?[-a-zA-Z0-9./_]+											{
																		if(errsExist) {
																			return ERROR;
																		}
																		int result = expandAliases(yytext);
																		if(!result) {
																			BEGIN 0;
																			yylval.str = strdup(yytext);
																			trim(yylval.str);
																			return CMD;
																		} else if(result == -1) {
																			errsExist = 1;
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

<PS>\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|:;',.<> \t]*(\\\")*)*\"	{
																		if(errsExist) {
																			return ERROR;
																		}
																		yytext[yyleng - 1] = 0;		//Remove trailing quote.
																		trim(yytext);				//Remove whitespace before first quote
																		int result = expandAliases(&yytext[1]);
																		if(!result) {
																			yylval.str = strdup(&yytext[1]);
																			return CMD;
																		} else if(result == -1) {
																			errsExist = 1;
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

<PS>-*([-a-zA-Z0-9.:/_]+(\\[ a-zA-Z0-9<>|"\\&*?]?)*)*				{
																		if(errsExist) {
																			return ERROR;
																		}
																		trim(yytext);
																		removeEscapes(yytext, yyleng);
																		int result = expandAliases(yytext);
																		if(!result) {
																			yylval.str = strdup(yytext);
																			return CMD;
																		} else if(result == -1) {
																			errsExist = 1;
																			return ERROR;
																		} else {
																			BEGIN AM;
																		}
																	}

<AM>[ \t]*("./")?[-a-zA-Z0-9./_]+									{
																		if(errsExist) {
																			return ERROR;
																		}
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
																				errsExist = 1;
																				return ERROR;
																			}
																		}
																	}

<AM>\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|:;',.<> \t]*(\\\")*)*\"	{
																		if(errsExist) {
																			return ERROR;
																		}
																		if(!aliased) {
																			BEGIN 0;
																			yyless(0);
																		} else {
																			yytext[yyleng - 1] = 0;		//Remove trailing quote.
																			trim(yytext);				//Remove whitespace before first quote
																			int result = expandAliases(&yytext[1]);
																			if(!result) {
																				BEGIN 0;
																				yylval.str = strdup(&yytext[1]);

																				if(parentAlias != NULL) {
																					free(parentAlias);
																					parentAlias = NULL;
																				}
																				aliased = 0;

																				return CMD;
																			} else if(result == -1) {
																				BEGIN 0;
																				errsExist = 1;
																				return ERROR;
																			}
																		}
																	}

<AM>-*([-a-zA-Z0-9.:/_]+(\\[ a-zA-Z0-9<>|"\\&*?]?)*)*				{
																		if(errsExist) {
																			return ERROR;
																		}
																		if(!aliased) {
																			BEGIN 0;
																			yyless(0);
																		} else {
																			trim(yytext);
																			removeEscapes(yytext, yyleng);
																			int result = expandAliases(yytext);
																			if(!result) {
																				BEGIN 0;
																				yylval.str = strdup(yytext);

																				if(parentAlias != NULL) {
																					free(parentAlias);
																					parentAlias = NULL;
																				}
																				aliased = 0;

																				return CMD;
																			} else if(result == -1) {
																				BEGIN 0;
																				errsExist = 1;
																				return ERROR;
																			}
																		}
																	}

<INITIAL,PS,BI>"|"													{
																		if(errsExist) {
																			return ERROR;
																		}
																		if(YY_START == BI) {
																			fprintf(stderr, ANSI_COLOR_RED "Error: I/O redirection is not supported with builtin commands.\n" ANSI_COLOR_RESET);

																			if(parentAlias != NULL) {
																				free(parentAlias);
																				parentAlias = NULL;
																			}
																			aliased = 0;
																			errsExist = 1;

																			return ERROR;
																		}
																		BEGIN PS;
																		return *yytext;
																	}

<INITIAL,BI>\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|:;',.<> \t]*(\\\")*)*\"	{
																		if(errsExist) {
																			return ERROR;
																		}
																		char temp = yytext[yyleng - 1];

																		yytext[yyleng - 1] = 0;					/* Remove the trailing '"' */
																		yylval.str = strdup(&yytext[1]);		/* Don't copy the '"' */

																		yytext[yyleng - 1] = temp;
																		int argLength = yyleng - 2;

																		removeEscapedQuotes(yylval.str, argLength);

																		return ARG;
																	}
<INITIAL,BI>-*([-a-zA-Z0-9.:/_+=()^%$#@!`,]+(\\[ a-zA-Z0-9<>|"\\&*?]?)*)*		{
																		if(errsExist) {
																			return ERROR;
																		}
																		yylval.str = strdup(yytext);

																		removeEscapes(yylval.str, yyleng);

																		return ARG;
																	}
<INITIAL,BI>~?(([-a-zA-Z0-9.:/_+=()^%$#@!`,]*(\\[ a-zA-Z0-9<>|"\\&*?])*)*[*?]+([-a-zA-Z0-9.:/_+=()^%$#@!`,]*(\\[ a-zA-Z0-9<>|"\\&*?])*)*)+		{
																		if(errsExist) {
																			return ERROR;
																		}
																		removeEscapes(yytext, yyleng);
																		int matches = expandWildcards(yytext);
																		if(matches == -1) {
																			BEGIN 0;
																			if(parentAlias != NULL) {
																				free(parentAlias);
																				parentAlias = NULL;
																			}
																			aliased = 0;
																			errsExist = 1;

																			return ERROR;
																		} else if(matches == 1) {
																			fprintf(stderr, ANSI_COLOR_RED "Error: No files found that match %s\n" ANSI_COLOR_RESET, yytext);

																			BEGIN 0;
																			if(parentAlias != NULL) {
																				free(parentAlias);
																				parentAlias = NULL;
																			}
																			aliased = 0;
																			errsExist = 1;

																			return ERROR;
																		}
																	}

<INITIAL,BI>"${"(\"([-a-zA-Z0-9.:/_\\?*`~!@#$%^&*()+={}[\]|;',<> \t]*(\\\")*)*\")"}"	{
																		if(errsExist) {
																			return ERROR;
																		}
																		yytext[yyleng - 2] = 0;						/* Remove the trailing '"}' */
																		int argLength = yyleng - 5;					/* New length of yylval.str */

																		removeEscapedQuotes(&yytext[3], argLength);	/* Remove escaped quotes. */

																		/* Replace/expand the environmental variable.  If there was an error, return ERROR. */
																		if(replaceEnvVar(&yytext[3]) == -1) {
																			if(parentAlias != NULL) {
																				free(parentAlias);
																				parentAlias = NULL;
																			}
																			aliased = 0;
																			errsExist = 1;

																			return ERROR;
																		}
																	}
<INITIAL,BI>"${"([-a-zA-Z0-9.:/_()?*`~!@#$%^&=+\]|;',<> \t]+)"}"	{
																		if(errsExist) {
																			return ERROR;
																		}
																		yytext[yyleng - 1] = 0;					/* Remove the trailing '}' */
																		int argLength = yyleng - 3;				/* Length of arg as seen by replaceEnvVar */

																		removeEscapes(yylval.str, yyleng);		/* Remove escaped characters. */

																		/* Replace/expand the environmental variable.  If there wa an error, return ERROR. */
																		if(replaceEnvVar(&yytext[2]) == -1) {
																			if(parentAlias != NULL) {
																				free(parentAlias);
																				parentAlias = NULL;
																			}
																			aliased = 0;
																			errsExist = 1;

																			return ERROR;
																		}
																	}

"2>"																{
																		if(errsExist) {
																			return ERROR;
																		}
																		return ERR_2_FILE;
																	}

"2>&1"																{
																		if(errsExist) {
																			return ERROR;
																		}
																		return ERR_2_OUT;
																	}

[<>&]																{
																		if(errsExist) {
																			return ERROR;
																		}
																		return *yytext;
																	}

">>"																{
																		if(errsExist) {
																			return ERROR;
																		}
																		return OUT_RA;
																	}

">&"																{
																		if(errsExist) {
																			return ERROR;
																		}
																		return OUT_ERR_R;
																	}

">>&"																{
																		if(errsExist) {
																			return ERROR;
																		}
																		return OUT_ERR_RA;
																	}

<INITIAL,BI>~"/"(("/"?[-a-zA-Z0-9._+=()^%$#@!`,]*(\\[ <>|"\\&]+)*)?)*			{
																		if(errsExist) {
																			return ERROR;
																		}
																		yylval.str = strdup(yytext);
																		removeEscapes(yylval.str, yyleng);
																		return EXPANDED_FILE;
																	}

<INITIAL,BI>~														{
																		if(errsExist) {
																			return ERROR;
																		}
																		yylval.str = strdup(yytext);
																		return EXPANDED_FILE;
																	}

<INITIAL,BI>~[-a-zA-Z0-9_+=()^%$#@!`,]+("/"?[-a-zA-Z0-9._+=()^%$#@!`,]*(\\[ <>|"\\&]+)?)*	{
																		if(errsExist) {
																			return ERROR;
																		}
																		yylval.str = strdup(yytext);
																		removeEscapes(yylval.str, yyleng);
																		return EXPANDED_USER;
																	}

<*>([-a-zA-Z0-9./_%$#@!^=+,]*(\\[ &]+)?)+\x1B						{
																		if(errsExist) {
																			return ERROR;
																		}
																		yylval.str = strdup(yytext);
																		removeEscapes(yylval.str, yyleng);
																		if(expandFileName(yylval.str, yyleng) == 0)
																			return ARG;
																		else {
																			errsExist = 1;
																			return ERROR;
																		}
																	}

<*>~[-a-zA-Z0-9_]+([-a-zA-Z0-9./_%$#@!^=+,]*(\\[ &]+)?)*\x1B		{
																		if(errsExist) {
																			return ERROR;
																		}
																		yylval.str = strdup(yytext);
																		removeEscapes(yylval.str, yyleng);
																		if(expandUserFileName(yylval.str, yyleng) == 0) {
																			return ARG;
																		}
																		else {
																			errsExist = 1;
																			return ERROR;
																		}
																	}

<*>[ \t]+															/* ignore white space */;

<INITIAL,BI,PS,AM>.													{
																		if(errsExist) {
																			return ERROR;
																		}
																		BEGIN ERR;

																		unput(*yytext);
																	}
<ERR>.*																{
																		BEGIN 0;

																		fprintf(stderr, ANSI_COLOR_RED "Error: %s not recognized.\n" ANSI_COLOR_RESET, yytext);

																		if(parentAlias != NULL) {
																			free(parentAlias);
																			parentAlias = NULL;
																		}
																		aliased = 0;
																		errsExist = 1;

																		return ERROR;

																	}

<INITIAL,BI,ERR>\n													{
																		BEGIN 0;
																		errsExist = 0;
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
* Expand partially typed files.  If only one match was found, place this value in filename and
* return 0.  If no matches were found, return 1.  If multiple matches were found, print them
* to the screen and return 1.
*/
int expandFileName(char *filename, int fileLength) {
	char return_value = 1;
	filename[fileLength - 1] = 0;	//Ignore `esc` character

	//If the filename contains a path, find the last '/'
	int i = 0, j = -1;
	while(filename[i]) {
		if(filename[i] == '/') {
			j = i;
		}
		i++;
	}

	char *directory;
	char *pattern;

	if(j == -1) {
		directory = (char *) malloc(1 * sizeof(char));
		directory[0] = '.';
		directory[1] = 0;

		pattern = (char *) malloc((strlen(filename) + 2) * sizeof(char));
		strcpy(pattern, filename);
		strcat(pattern, "*");		//Add wildcard to the end of the file path.
	} else {
		directory = (char *) malloc((j + 2) * sizeof(char));
		strncpy(directory, filename, j + 1);
		directory[j+1] = 0;

		pattern = (char *) malloc(strlen((&filename[j]) + 1) * sizeof(char));
		strcpy(pattern, &filename[j + 1]);
		strcat(pattern, "*");
	}

	free(filename);

	DIR *dir;
	if((dir = opendir(directory)) == NULL) {
		fprintf(stderr, ANSI_COLOR_RED "Error: Directory %s could not be opened.\n" ANSI_COLOR_RESET, directory);
		return -1;
	}

	struct dirent *file;
	i = 0;
	while((file = readdir(dir)) != NULL) {
		if(fnmatch(pattern, file->d_name, FNM_PATHNAME | FNM_PERIOD) == 0) {
			//Match
			if(i == 0) {
				yylval.str = filename = strdup(file->d_name);
				yyleng = strlen(filename);

				return_value = 0;
			} else {
				if(i == 1) {
					fprintf(stderr, ANSI_COLOR_GREEN "%s\t", filename);
				}

				if((i % 3) == 0) {
					fprintf(stderr, ANSI_COLOR_GREEN "%s\n", file->d_name);
				} else {
					fprintf(stderr, ANSI_COLOR_GREEN "%s\t", file->d_name);
				}

				return_value = 1;
			}

			i++;
		}
	}

	if(i > 1 && i % 3) {
		fprintf(stderr, ANSI_COLOR_RED "\n\nMultiple files match your query.  Please use one of the files above.\n");
	} else if(i > 1) {
		fprintf(stderr, ANSI_COLOR_RED "\nMultiple files match your query.  Please use one of the files above.\n");
	} else if(i == 0) {
		pattern[strlen(pattern) - 1] = 0;
		fprintf(stderr, ANSI_COLOR_RED "\nError: File matching pattern %s* in directory %s not found.\n", pattern, directory);
	}

	free(directory);
	free(pattern);
	closedir(dir);

	return return_value;
}

/**
* Expand partially typed user home files.  If only one match was found, obtain the home directory
* for this user and place this value in filename and return 0.  If no matches were found,
* return 1.  If multiple matches were found, print them to the screen and return 1.
*/
int expandUserFileName(char *filename, int fileLength) {
	char return_value = 1;
	filename[fileLength - 1] = 0;		//Ignore `esc` character

	//If the filename contains a path, find the first '/'
	int i = 0;
	while(filename[i] != '/' && filename[i] != 0) {
		i++;
	}

	char *directory = strdup(&filename[i]);

	char pattern[i + 1];
	strncpy(pattern, &filename[1], i - 1);
	pattern[i - 1] = 0;
	strcat(pattern, "*");		//Add wildcard to the end of the file path.

	free(filename);

	i = 0;
	struct passwd *user = NULL;
	char *first_dir = NULL;
	char *first_name = NULL;
	while((user = getpwent()) != NULL) {
		if(fnmatch(pattern, user->pw_name, 0) == 0) {
			//Match
			if(i == 0) {
				first_dir = strdup(user->pw_dir);
				first_name = strdup(user->pw_name);

				return_value = 0;
			} else {
				if(i == 1) {
					fprintf(stderr, ANSI_COLOR_GREEN "%s\t", first_name);
				}

				if((i % 3) == 0) {
					fprintf(stderr, ANSI_COLOR_GREEN "%s\n", user->pw_name);
				} else {
					fprintf(stderr, ANSI_COLOR_GREEN "%s\t", user->pw_name);
				}

				return_value = 1;
			}

			i++;
		}
	}

	if(i == 1) {
		yylval.str = filename = strdup(first_dir);
		strcat(filename, directory);
		yyleng = strlen(filename);
	}

	if(i > 0) {
		free(first_dir);
		free(first_name);
	}

	endpwent();

	if(i > 1 && i % 3) {
		fprintf(stderr, ANSI_COLOR_RED "\n\nMultiple users match your query.  Please use one of the users above.\n");
	} else if(i > 1) {
		fprintf(stderr, ANSI_COLOR_RED "\nMultiple users match your query.  Please use one of the users above.\n");
	} else if(i == 0) {
		pattern[strlen(pattern) - 1] = 0;
		fprintf(stderr, ANSI_COLOR_RED "\nError: User starting with %s not found.\n", pattern);
	}

	return return_value;
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
int expandWildcards(char *arg) {
	char return_value = 1;

	char *argument = strdup(arg);

	if(argument[0] == '~') {
		//Needs tilde expansion, determine what kind.  Argument has to contain a '/' since there is a wildcard present
		char *temp = (char *) malloc((strlen(argument) + 1) * sizeof(char));
		strcpy(temp, argument);
		free(argument);
		argument = NULL;

		if(temp[1] == '/') {
			argument = (char *) replaceTilde(argument, temp);
		} else {
			argument = (char *) replaceUserTilde(argument, temp);
		}

		free(temp);
	}

	//If the argument contains a path, find the last '/'
	int i = 0, j = -1;
	while(argument[i] && argument[i] != '*') {
		if(argument[i] == '/') {
			j = i;
		}
		i++;
	}

	char *directory;
	char *pattern; 

	if(j == -1) {
		directory = (char *) malloc(2 * sizeof(char));
		directory[0] = '.';
		directory[1] = 0;

		pattern = (char *) malloc((strlen(argument) + 1) * sizeof(char));
		strcpy(pattern, argument);
	}
	else {
		directory = (char *) malloc((j + 2) * sizeof(char));
		strncpy(directory, argument, j + 1);
		directory[j+1] = 0;

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

			if(directory[0] != '/' && file->d_name[strlen(file->d_name) - 1] != '/')
				unput('/');

			i = strlen(directory) - 1;
			while(i >= 0) {
				unput(directory[i--]);
			}

			unput('"');

			return_value = 0;
		}
	}

	free(directory);
	free(pattern);

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