# COP5614-FinalProject

Group:
* Md Shahadat Iqbal
* Md Abdullah Al Mamun
* Vitalii Stebliankin

To compile the code, run the following in the project directory:

	make

To perform initial testing, that involves creating, reading/writing, and removing file or directory, run the following:

	./simple-test.exe <disk-name>


To list directory, run the following:

	/slow-ls.exe <disk-name> /path/to/directory

To create and empty file:

	/slow-touch.exe <disk-name> /path/to/file

To create directory:

	/slow-mkdir.exe <disk-name> /path/to/directory

To import file from unix to our file system:

	/slow-export <disk-name> /path/from/unix /path/in/slow-file-system

To import export from our file system to unix:

	/slow-export <disk-name> /path/to/unix /path/in/slow-file-system	

## Notes

Before executing make file add the following to .bashrc:

    export LD_LIBRARY_PATH="path/to/this/project"
