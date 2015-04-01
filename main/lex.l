%{
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#include "y.tab.h"

	void yyerror(char *);
%}

%x PS BI

%%

<*>alias|ALIAS 										{
														BEGIN BI;
														yylval.str = strdup("alias");
														return BUILTIN;
													}

<*>bye|BYE											{
														BEGIN BI;
														yylval.str = strdup("bye");
														return BUILTIN;
													}

<*>cd|CD 											{
														BEGIN BI;
														yylval.str = strdup("cd");
														return BUILTIN;
													}

<*>printenv|PRINTENV								{
														BEGIN BI;
														yylval.str = strdup("printenv");
														return BUILTIN;
													}

<*>setenv|SETENV									{
														BEGIN BI;
														yylval.str = strdup("setenv");
														return BUILTIN;
													}

<*>unalias|UNALIAS									{
														BEGIN BI;
														yylval.str = strdup("unalias");
														return BUILTIN;
													}

<*>unsetenv|UNSETENV								{
														BEGIN BI;
														yylval.str = strdup("unsetenv");
														return BUILTIN;
													}

^[ \t]*("./")?[a-zA-Z0-9./]+						{
														yylval.str = strdup(yytext);
														return CMD;
													}

<PS>("./")?[a-zA-Z0-9./]+							{
														BEGIN 0;
														yylval.str = strdup(yytext);
														return CMD;
													}

<INITIAL,PS>"|"										{
														BEGIN PS;
														return *yytext;
													}

<INITIAL,BI>-*[a-zA-Z0-9.:/]+						|
\"((.)*(\")*)*\"									|
-*([a-zA-Z0-9.:/]*\\[ a-zA-Z0-9<>|"\&])*			{
														yylval.str = strdup(yytext);
														return ARG;
													}

<INITIAL,BI>"${"-*[a-zA-Z0-9.:/]+"}"				|
"${"(\"((.)*(\")*)*\")"}"							|
"${"(-*([a-zA-Z0-9.:/]*\\[ a-zA-Z0-9<>|"\&])*)"}"	{
														yytext[yyleng - 1] = 0;					/* Remove the trailing '}' */
														yylval.str = strdup(&yytext[2]);		/* Don't copy the '${' */
														return ENV_VAR;
													}

2>													return ERR_2_FILE;

2>&1												return ERR_2_OUT;

[<>&]												return *yytext;

">>"												return OUT_RA;

">&"												return OUT_ERR_R;

">>&"												return OUT_ERR_RA;

~"/"[a-zA-Z0-9./]*									{
														yylval.str = strdup(yytext);
														return EXPANDED_FILE;
													}

~[a-zA-Z0-9]*"/"?[a-zA-Z0-9./]*						{
														yylval.str = strdup(yytext);
														return EXPANDED_USER;
													}

<*>[ \t]+											/* ignore white space */;

<*>.												{
														BEGIN 0;
														return ERROR;
													}

<INITIAL,BI>\n										{
														BEGIN 0;
														return EOC;
													}

%%

int yywrap() {
	return 1;
}