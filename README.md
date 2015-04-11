# YAS
Yet Another Shell.  Simplified (but awesome and well-written) shell built as a project for COP4600 (OS) that uses Lex and YACC to tokenize and parse input.

##How to Install and Run
To install YAS simply clone YAS (https://github.com/c1moore/YAS.git) then execute the following commands on the command line:
```
cd YAS
make
./yas
```

##What's Supported?
#####Escaping
All characters between double quotes (`"`) are treated as a single word and all metacharacters are ignored.  The only exception to this is when there is a backslash followed by a double quote (`\"`) in which case the backslash is removed and the double quote is ignored.  A single metacharacter can be ignored using a backslash (`\`).  For example `ls "This is a file.txt"` and `ls This\ is\ a\ file.txt` would both search the current directory for a file with the name `This is a file.txt`.
#####Aliases
Aliases are only expanded for the first word that begins a command, including after pipe (e.g. alias1 | alias2 will be expanded properly).  Aliases themselves can contain any string that results to one or more valid commands (e.g. "ls | sort" is a valid alias).
#####I/O redirection
- Pipes - we allow up to 50 commands to be piped together.  If more space is needed, we suggest on the last command you use output redirection to pipe the results of the last command to a file and use this file as input to the next command you wanted to pipe.
- Input redirection - Achieved the same way you would expect.  Simply use the `<` operator and specify an existing file from which to obtain input.
- Output redirection - There are two different flavors of output redirection.  Both of these methods create a file if the specified file could not be found.
  - To overwrite an existing file, use the `>` operator
  - To append to the end of an existing file, use the `>>` operator.
- Error redirection - Error redirection also comes in two different flavors
  - To send error to a file, use the `2>` operator and specify the filename.  If the file is not found, a new file with the specified name will be created.
  - To redirect error to standard output, use the `2>&1` operator.

#####Background Processing
If `&` is specified at the end of a command or a pipeline of commands, all the commands will be run in the background so you can continue executing commands.  When the command (or commands) have finished running, the result will be printed to the screen.
#####Environmental Variable Expansion
When placed between `${` and `}`, an environmental variable will be expanded.  Escaping is supported within the curly brackets.
#####Wildcard Matching
The typical wildcard matching supported by most shells is supported here.  An asterisk (`*`) after a partial file name will return any file that contains 0, 1, or more characters where the asterisk occurs.  A question mark (`?`) only matches a single character.
#####Tilde Expansion
**Wildcard matching is not supported with tilde expansion**.  There are two basic constructs that are allowed with tilde expansion.  They are as follows:
- <b>~name[/dir]</b> - `~name` will be replaced by the user's home directory whose username is `name`.  The optional `/dir` will be appended to the end of this directory.  For example, given c1moore's home directory is `/home/c1moore`, `~c1moore/yas` will be expaned to `/home/c1moore/yas`
- <b>~[/dir]</b> - `~` will be replaced by the current user's home directory.  The optional `/dir` will be appended to the end of this directory.

#####File Name Completion
**Wildcard matching is not supported with file name completion**.  When typing a file name, pressing the `esc` character will expand the file name **after** you press the `enter` key (i.e. begin execution).  If the file name is ambiguous, a list of possible files that match the file name specified will be printed to the screen.

##Built-in Commands
Built-in commands do *not* support I/O redirection.  Furthermore, built-in commands cannot be run in the background.
- <b>setenv variable word</b> Set environmental variable `variable` to equal `word`
- <b>printenv</b> Print all environmental variables
- <b>unsetenv variable</b> Remove environmental variable `env`
- <b>cd dir</b> Switch the current working directory to `dir`.  Not specifying a directory is equivalent to `cd ~`
- <b>alias name word</b> Adds a new alias to the current shell session.  When no alias is specified, all current aliases are printed.
- <b>unalias name</b> Remove alias `name`
- <b>bye</b> Exit from the shell
- <b>debug</b> Run the shell in debug mode (i.e. print out all commands, args, and I/O redirections after the command has terminated).
- <b>help</b> Obtain more help
