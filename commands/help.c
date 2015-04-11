#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <yas.h>

int help(int argc, char *argv[]) {
	int cd;
	char *cmds[] = {"1. alias", "2. bye", " 3. cd", "4. printenv", "5. setenv", "6. unalias", "7. unsetenv"};
	//if cd has no arguments go to the home dir else go to the directort in the argument
	if(argc == 1) {
		int cmd;
		printf("Select a command to get help on:\n");
		while(cmds) {
			printf("%s\n");
			cmds++
		}
		scanf("%d",cmd);
		printf("Command usage:\n");
		switch (cmd) {
			case 1:
				printf("alias [alias name] [command]\n");
			case 2:
				printf("bye");
			case 3:
				printf("cd [directory]\n");
			case 4:
				printf("printenv");
			case 5:
				printf("setenv [ENV Name] [Variable]");
			case 6:
				printf("unalias [alias name]");
			case 7:
				printf("unsetenv [alias name]");
		}
		return(0);
	}
}