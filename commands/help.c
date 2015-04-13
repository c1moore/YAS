#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <yas.h>

/* This command currently presents the users with a lists of builtin commands, 
and the user can select one to see the command usage.*/
int help(int argc, char *argv[]) {
	int cd;
	char * cmds[] = {"1. alias", "2. bye", "3. cd", "4. printenv", "5. setenv", "6. unalias", "7. unsetenv"};
	int cmdsLength = sizeof(cmds)/sizeof(const char *);
	//if cd has no arguments go to the home dir else go to the directort in the argument
	if(argc) {
		int cmd;
		int i;
		for(i=0;i<cmdsLength;i++) {
			printf("%s\n",cmds[i]);
		}
		printf("Select a command to get help on: ");
		scanf("%d",&cmd);
		printf("Command usage:\n");
		switch (cmd) {
			case 1:
				printf("alias [alias name] [command]");
				break;
			case 2:
				printf("bye");
				break;
			case 3:
				printf("cd [directory]");
				break;
			case 4:
				printf("printenv");
				break;
			case 5:
				printf("setenv [ENV Name] [Variable]");
				break;
			case 6:
				printf("unalias [alias name]");
				break;
			case 7:
				printf("unsetenv [alias name]");
				break;
		}
		return(0);
	}
}