#include <syscall.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <yas.h>

int alias(int argc, char *argv[]) {
	struct yas_alias *next, *curr, *prev;		//gathers linked list structure

	/*if only the alias command is typed iterate through
	the linked list of aliases and print all the aliases 
	in the form of alias = cmd */
	if (argc == 1) {
		curr = alias_head->next;	
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
		//makes sure that the cmd being set is not longer than 50 characters
		if(strlen(argv[2]) > 50) {
			fprintf(stderr,"Command is to long. Commands can hace at most 50 characters.");
			return(ARG_ERR);
		}

		//stops aliases being set to themselves
		if(strcmp(argv[1],argv[2]) == 0) {
			perror("Aliases cannot be set to themselves.");
			return(ARG_ERR);
		}

		prev = alias_head;
		curr = alias_head->next;	//gets alias tab head

		/*goes theough aliastab until it reaches the end of the list.*/
		while (curr != NULL) {
			if(strcmp(argv[1],curr->alias) == 0) {
				fprintf(stderr,"Alias %s is already set with command %s",argv[1],curr->cmd);
				return(BUILTIN_ERR);
			}
			//alerts use that the alias is already a system command or that the cmd is already
			/*else if(strcmp(argv[1],curr->alias) == 0 || strcmp(argv[1],curr->cmd) == 0) {
				fprintf(stderr,"Alias %s is already set with command %s",argv[1],curr->cmd);
				return(BUILTIN_ERR);
			}*/	
			prev = curr;
			curr = curr->next;
		}

		curr = prev;

		struct yas_alias *new_alias;
		new_alias = (struct yas_alias*)malloc(sizeof(struct yas_alias));		//creates new ending node
		curr->next = new_alias;

		new_alias->alias = (char *) malloc((strlen(argv[1])+1) * sizeof(char));			//sets new node with the alias
		strcpy(new_alias->alias, argv[1]);
		
		new_alias->cmd = (char *) malloc((strlen(argv[2])+1) * sizeof(char));			//sets new node with command
		strcpy(new_alias->cmd, argv[2]);	
		
		new_alias->next = NULL;				//sets next node to be NULL
		num_aliases++;							//increments num_aliases global variable

		printf("%s = %s\n",new_alias->alias,new_alias->cmd);
		return(0);
	}
	
	/*if anyother form of the alias command is typed, print out an error
	and a message showing the correct usage of alias*/ 
	else {
		printf("Incorrect usage\n Usage: alias [alias name] [alias cmd]");
		return(ARG_ERR);
	}
}