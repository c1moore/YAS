%{
#include <stdlib.h>
void yyerror(char *);
%}

%%
^[ \t]*[a-zA-z]++                   |
"|"[ \t]*?[a-zA-z]++                |
^[ \t]*"./"[a-zA-z"/"]++            |
"|"[ \t]*"./"[a-zA-z"/"]++          printf("CMD\n");

[a-zA-z"/"]++                       printf("ARG\n");

">>"                                printf("OUT_RA\n");

">&"                                printf("OUT_ERR_R\n");

">>&"                               printf("OUT_ERR_RA\n");

~"/"[a-zA-Z0-9."/"]*                printf("EXPANDED_FILE\n");

~[a-zA-Z0-9]*[a-zA-Z0-9."/"]*       printf("EXPANDED_USER\n");;

[ \t]+                              /* ignore white space */;

.                                   yyerror("What is this nonsense?! I don't know this char!\n");
%%

void yyerror(char * error) {
    printf("%s",error);
}