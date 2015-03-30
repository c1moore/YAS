#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>

int setenv(int argc, char *argv[]) {
	if(argc < 3 || argc > 4) {
		printf("Error: Invalid arguments. setenv takes at most 3 arguments.\n");	//displays error if more than two arg
		exit(0);
	}
	int set;

	if (argc == 3) {
		set = setenv(argv[1], argv[2], 0);
	}

	//if setenv doesn't fail exit. Else report the error
	if(set != -1) {
		exit(0);			
	}
	else {
		perror("Error: ");
	}
}