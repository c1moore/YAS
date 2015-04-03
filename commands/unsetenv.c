#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <yas.h>

int unenv(int argc, char *argv[]) {
	if(argc != 2) {
		printf("Error: Invalid arguments. setenv requires 1 argument.\n");	//displays error if more than two arg
		return(ARG_ERR);
	}

	int	un = unsetenv(argv[1]);

	//if setenv doesn't fail exit. Else report the error
	if(un != -1) {
		return(0);			
	}
	else {
		perror("Error ");
	}
}