#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <yas.h>
#include <errno.h>

int env(int argc, char *argv[]) {
	int set;
	if (argc == 3) {
		set = setenv(argv[1], argv[2], 0);
		fprintf(stderr, "setenv set" );
	}
	else {
		printf("Error: Invalid arguments. setenv takes at most 3 arguments.\n");	//displays error if more than two arg
		return(ARG_ERR);
	}
	
	//if setenv doesn't fail exit. Else report the error
	if(set != -1) {
		return(0);			
	}
	else {
		perror("Error: ");
		return(BUILTIN_ERR);
	}
}