%{
#include <stdlib.h>
#include "calc3.h"
#include "y.tab.h"
void yyerror(char *);
%}

%%
^[ \n\t]*[a-zA-z]++[\n\t]*         return CMD
[|][ \n\t]*[a-zA-z]++[ \n\t]*       |


[ \n\t]*[a-zA-z\]++[\n]|[         return ARG

">>"                                return OUT_RG

">&"                                return OUT_ERR.OUT_RG

">>&"                               return OUT_ERR_RA


>[a-zA-Z0-9<>"\&]* | yyerror
\[<>|'&*']         return