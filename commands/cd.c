#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
	if(argc > 2) {
		printf("Error: Too many arguments. cd accepts only one argument.\n");	//displays error if more than one arg
		exit(0);
	}

	int cd;
	//if cd has no arguments go to the home dir else go to the directort in the argument
	if(argc == 1) {
		cd = chdir(getenv("HOME"));
	}
	else {
		cd = chdir(argv[1]);
	}

	//if chdir doesn't fail exit. Else report the error
	if(cd != -1) {
		exit(0);			
	}
	else {
		perror("Error: ");
	}
}