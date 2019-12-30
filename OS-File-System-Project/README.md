# OS Project: Slower File System Imlementation

The project focus on developing a file management system. The main objectives of this project
are:
* Gain a details understanding on how does file system work, specifically the directory
hierarchy and storage management.
* Gain an understanding on some of the performance issues file systems must deal with.
In this project, we have built the user-level library, libFS, that can simulate some of the functions
of a 
* File management system.

Video: https://youtu.be/fL1RNKb2dQA 

Implemented By:
* Md Abdullah Al Mamun
* Md Shahadat Iqbal
* Vitalii Stebliankin

# How to run and test
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

* Reference: https://github.com/jorvel/COP4610-HW5 
