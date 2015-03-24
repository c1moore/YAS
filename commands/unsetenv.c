#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
	if(argc != 2 || argc > 4) {
		printf("Error: Invalid arguments. setenv requires 1 argument.\n");	//displays error if more than two arg
		exit(0);
	}

	int	un = unsetenv(argv[1]);

	//if setenv doesn't fail exit. Else report the error
	if(un != -1) {
		exit(0);			
	}
	else {
		perror("Error: ");
	}
}