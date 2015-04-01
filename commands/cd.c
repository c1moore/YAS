#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>

int cd(int argc, char *argv[]) {
	int cd;

	//if cd has no arguments go to the home dir else go to the directort in the argument
	if(argc == 1) {
		cd = chdir(getenv("HOME"));
	}
	else if (argc == 2) {
		cd = chdir(argv[1]);
	}
	else {
		printf("Error: Too many arguments. cd accepts only one argument.\n");	//displays error if more than one arg
		exit(0);
	}

	//if chdir doesn't fail exit. Else report the error
	if(cd != -1) {
		return(0);			
	}
	else {
		perror("Error");
	}
}