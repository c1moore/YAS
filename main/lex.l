%{
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#include "y.tab.h"

	void yyerror(char *);
%}

%x PS

%%

^[ \t]*("./")?[a-zA-z0-9./]+				{
												yylval.str = strdup(yytext);
												return CMD;
											}

<PS>("./")?[a-zA-z0-9./]+					{
												BEGIN 0;
												return CMD;
											}

<*>"|"										{
												BEGIN PS;
												return *yytext;
											}

-*[a-zA-z0-9.:/]+							|
\"((.)*(\")*)*\"							|
-*([a-zA-Z0-9.:/]*\\[ a-zA-Z0-9<>|"\&])*	{
												yylval.str = strdup(yytext);
												return ARG;
											}

2>											return ERR_2_FILE;

2>&1										return ERR_2_OUT;

[<>&]										return *yytext;

">>"										return OUT_RA;

">&"										return OUT_ERR_R;

">>&"										return OUT_ERR_RA;

~"/"[a-zA-Z0-9./]*							{
												yylval.str = strdup(yytext);
												return EXPANDED_FILE;
											}

~[a-zA-Z0-9]*"/"?[a-zA-Z0-9./]*				{
												yylval.str = strdup(yytext);
												return EXPANDED_USER;
											}

<*>[ \t]+									/* ignore white space */;

<*>.										yyerror("What is this nonsense?! I don't know this char!");

\n 											return EOC;

%%

int yywrap() {
	return 1;
}