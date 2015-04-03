%{
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#include "y.tab.h"
	#include "yas.h"

	int expandAliases(char *);
	void removeEscapes(char *, int);
	void removeEscapedQuotes(char *, int);

	void yyerror(char *);
%}

%x PS BI

%%

<*>alias|ALIAS 														{
																		BEGIN BI;
																		yylval.str = strdup("alias");
																		builtin = BUILTIN_ALIAS;
																		return BUILTIN;
																	}

<*>bye|BYE															{
																		BEGIN BI;
																		yylval.str = strdup("bye");
																		builtin = BUILTIN_BYE;
																		return BUILTIN;
																	}

<*>cd|CD 															{
																		BEGIN BI;
																		yylval.str = strdup("cd");
																		builtin = BUILTIN_CD;
																		return BUILTIN;
																	}

<*>printenv|PRINTENV												{
																		BEGIN BI;
																		yylval.str = strdup("printenv");
																		builtin = BUILTIN_PRNTENV;
																		return BUILTIN;
																	}

<*>setenv|SETENV													{
																		BEGIN BI;
																		yylval.str = strdup("setenv");
																		builtin = BUILTIN_SETENV;
																		return BUILTIN;
																	}

<*>unalias|UNALIAS													{
																		BEGIN BI;
																		yylval.str = strdup("unalias");
																		builtin = BUILTIN_UNALIAS;
																		return BUILTIN;
																	}

<*>unsetenv|UNSETENV												{
																		BEGIN BI;
																		yylval.str = strdup("unsetenv");
																		builtin = BUILTIN_UNENV;
																		return BUILTIN;
																	}

^[ \t]*("./")?[a-zA-Z0-9./]+										{
																		if(!expandAliases(yytext)) {
																			yylval.str = strdup(yytext);
																			return CMD;
																		}
																	}

<PS>("./")?[a-zA-Z0-9./]+											{
																		if(!expandAliases(yytext)) {
																			BEGIN 0;
																			yylval.str = strdup(yytext);
																			return CMD;
																		}
																	}

<INITIAL,PS>"|"														{
																		BEGIN PS;
																		return *yytext;
																	}

<INITIAL,BI>\"((.)*(\")*)*\"										{
																		yytext[yyleng - 1] = 0;					/* Remove the trailing '"' */
																		yylval.str = strdup(&yytext[1]);		/* Don't copy the '"' */
																		yyleng -= 2;

																		removeEscapedQuotes(yylval.str, yyleng);

																		return ARG;
																	}
<INITIAL,BI>-*([a-zA-Z0-9.:/]+(\\[ a-zA-Z0-9<>|"\\&]?)*)*			{
																		yylval.str = strdup(yytext);

																		removeEscapes(yylval.str, yyleng);

																		return ARG;
																	}

<INITIAL,BI>"${"(\"((.)*(\")*)*\")"}"								{
																		yytext[yyleng - 2] = 0;					/* Remove the trailing '"}' */
																		yylval.str = strdup(&yytext[3]);		/* Don't copy the '${"' */
																		yyleng -= 5;							/* New length of yylval.str */

																		removeEscapedQuotes(yylval.str, yyleng);

																		return ENV_VAR;
																	}
<INITIAL,BI>"${"(-*([a-zA-Z0-9.:/]+(\\[ a-zA-Z0-9<>|"\\&])?)*)"}"	{
																		yytext[yyleng - 1] = 0;					/* Remove the trailing '}' */
																		yylval.str = strdup(&yytext[2]);		/* Don't copy the '${' */
																		yyleng -= 3;

																		removeEscapes(yylval.str, yyleng);

																		return ENV_VAR;
																	}

2>																	return ERR_2_FILE;

2>&1																return ERR_2_OUT;

[<>&]																return *yytext;

">>"																return OUT_RA;

">&"																return OUT_ERR_R;

">>&"																return OUT_ERR_RA;

<INITIAL,BI>~("/"[a-zA-Z0-9./]*)?									{
																		yylval.str = strdup(yytext);
																		return EXPANDED_FILE;
																	}

<INITIAL,BI>~[a-zA-Z0-9]+"/"?[a-zA-Z0-9./]*							{
																		yylval.str = strdup(yytext);
																		return EXPANDED_USER;
																	}

<*>[ \t]+															/* ignore white space */;

<*>.																{
																		BEGIN 0;
																		return ERROR;
																	}

<INITIAL,BI>\n														{
																		BEGIN 0;
																		return EOC;
																	}

%%

/**
* Check if a command is an alias.  If so handle it and return 1; otherwise, return 0.
*/
int expandAliases(char *command) {
	if(num_aliases == 0) {
		//No aliases
		return 0;
	}

	int i;
	struct yas_alias *curr = alias_head->next;

	for(i = 0; i < num_aliases; i++) {
		if(!strcmp(curr->alias, command)) {
			//Add chars from the expanded command to the input stream for Lex in reverse order (unput chars are added to the beginning of the stream).
			int len = strlen(curr->cmd);
			while(len >= 0) {
				unput(curr->cmd[len--]);
			}

			break;
		}

		curr = curr->next;
	}

	return !(i == num_aliases);
}

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

int yywrap() {
	return 1;
}