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
												fprintf(stderr, "%s\n", "Lex1");
												yylval.str = strdup(yytext);
												return CMD;
											}

<PS>[ \t]*("./")?[a-zA-z0-9./]+					{
												fprintf(stderr, "%s\n", "Lex2");
												BEGIN 0;
												return CMD;
											}

<*>"|"										{
												printf("Found pipe.\n");
												fprintf(stderr, "%s\n", "Pipe");
												fflush(stderr);
												BEGIN PS;
												fprintf(stderr, "%s\n", "Piping begun.");
												return EOC;
											}

-*[a-zA-z0-9.:/]+							|
\"((.)*(\")*)*\"							|
-*([a-zA-Z0-9.:/]*\\[ a-zA-Z0-9<>|"\&])*	{
												fprintf(stderr, "%s\n", "Lex3");
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
												fprintf(stderr, "%s\n", "Lex4");
												yylval.str = strdup(yytext);
												return EXPANDED_FILE;
											}

~[a-zA-Z0-9]*"/"?[a-zA-Z0-9./]*				{
												fprintf(stderr, "%s\n", "Lex5");
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