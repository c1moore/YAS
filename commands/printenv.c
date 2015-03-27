#include <syscall.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
	if(argc != 1) {
		printf("Error: Invalid arguments. setenv does not accept arguments\n");	//displays error if more than two arg
		exit(0);
	}

	extern char **environ;		//defines the environ variable

	//goes through the environ array and prints the vars
	int i = 0;
	while(environ[i]) {
		printf("%s\n",environ[i++]);
	}
}