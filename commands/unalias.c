#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <yas.h>

int unalias(int argc, char *argv[]) {
	struct yas_alias *next, *curr;		//gathers linked list structure

	/*if unalias alias-name is typed this will search the aliastab
	for the given alias-name and remove it from alias tab. If the 
	alias-name is not found it will return an error to the console 
	reporting this to the user*/
	if (argc == 2) {
		/*if(getLength(argv[2]) > CMD_LENGTH) {
			exit(0);
		}*/

		curr = alias_head;
		if (strcmp(curr->next->alias,argv[1]) == 0) {
			curr->next = curr->next->next;
			free(curr->next->alias);
			free(curr->next->cmd);
			free(curr->next);
			curr = curr->next;
		}
		while (curr->next != NULL) {
			if (strcmp(curr->alias,argv[1]) == 0) {
				
			}
			curr = curr->next;
		}

		curr->next = malloc(sizeof(*curr));
		curr->alias = argv[1];
		curr->cmd = argv[2];
		curr->next->next = NULL;

		printf("%s = %s\n",curr->alias,curr->cmd);
		exit(0);
	}
	/*if anyother form of the alias command is typed, print out an error
	and a message showing the correct usage of alias*/ 
	else {
		printf("Incorrect usage\n Usage: alias [alias name] [alias cmd]");
		exit(0);
	}
}

/*int getLength(char *argv) {
	int length = 0;
	while(argv) {
		length++;
	}
	return length;
}*/