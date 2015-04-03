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
			return(0);
		}			
		while (curr != NULL) {
			printf("%s = %s\n",curr->alias,curr->cmd);
			curr = curr->next;
		}
		return(0);
	}

	/*if alias alias-name cmd is typed this goes throught the 
	aliastab and adds the new alias to the tail of the aliastab
	list. Once completed it will print the alias and command added
	in the form of alias = cmd */
	else if (argc == 3) {
		/*if(getLength(argv[2]) > CMD_LENGTH) {
			exit(0);
		}*/

		//stops aliases being set to themselves
		if(argv[1] == argv[2]) {
			printf("You can't do that");
			return(ARG_ERR);
		}

		curr = alias_head;	//gets alias tab head

		/*goes theough aliastab until it reaches the end of the list. If
		at anypoint it catches either the inputed command or alias has been 
		taken it returns an error and alerts the user*/
		while (curr != NULL) {
			if(argv[2] == curr->cmd) {
				fprintf(stderr,"Command %s is already set with alias %s",argv[2],curr->alias);
				return(BUILTIN_ERR);
			}
			else if(argv[1] == curr->alias) {
				fprintf(stderr,"Alias %s is already set with command %s",argv[1],curr->cmd);
			}
			else {
				curr = curr->next;
			}
		}

		curr->next = malloc(sizeof(*curr));		//creates new ending node
		curr->alias = argv[1];					//sets new node with the alias
		curr->cmd = argv[2];					//and command
		curr->next->next = NULL;				//sets next node to be NULL

		printf("%s = %s\n",curr->alias,curr->cmd);
		return(0);
	}
	
	/*if anyother form of the alias command is typed, print out an error
	and a message showing the correct usage of alias*/ 
	else {
		printf("Incorrect usage\n Usage: alias [alias name] [alias cmd]");
		return(ARG_ERR);
	}
}

/*int getLength(char *argv) {
	int length = 0;
	while(argv) {
		length++;
	}
	return length;
}*/