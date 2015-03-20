%{
#include <stdlib.h>
#include "calc3.h"
#include "y.tab.h"
void yyerror(char *);
%}

%%
^[a-zA-z]++*                        return CMD
[|][ \n\t]*[a-zA-z]++[ \n\t]*       |

*[a-zA-z\]++                        return ARG

">>"                                return OUT_RG

">&"                                return OUT_ERR.OUT_RG

">>&"                               return OUT_ERR_RA

~"/"[a-zA-Z0-9."/"]*                return EXPANDED_FILE

~[a-zA-Z0-9]*[a-zA-Z0-9."/"]*         return EXPANDED_USER

[ /t]+                              /* ignore white space */

.                                   yyerror

%%

int yywrap(void) {
    return 1;
}