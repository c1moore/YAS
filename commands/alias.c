#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <yas.h>

int alias(int argc, char *argv[]) {
	struct yas_alias *next, *curr;		//gathers linked list structure

	/*if only the alias command is typed iterate through
	the linked list of aliases and print all the aliases 
	in the form of alias = cmd */
	if (argc == 1) {
		curr = alias_head;	
		if(!num_aliases) {
			printf("No aliases set\n");
			exit(0);
		}			
		while (curr != NULL) {
			printf("%s = %s\n",curr->alias,curr->cmd);
			curr = curr->next;
		}
		exit(0);
	}
	/*if alias alias-name cmd is typed this goes throught the 
	aliastab and adds the new alias to the tail of the aliastab
	list. Once completed it will print the alias and command added
	in the form of alias = cmd */
	else if (argc == 3) {
		/*if(getLength(argv[2]) > CMD_LENGTH) {
			exit(0);
		}*/

		curr = alias_head;
		while (curr != NULL) {
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