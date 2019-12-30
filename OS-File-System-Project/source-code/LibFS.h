/***************************/
/* DO NOT MODIFY THIS FILE */
/***************************/
    
#ifndef __LibFS_h__
#define __LibFS_h__

// error types
typedef enum {
    E_GENERAL,      // general
    E_CREATE, 
    E_NO_SUCH_FILE, 
    E_TOO_MANY_OPEN_FILES, 
    E_BAD_FD, 
    E_NO_SPACE, 
    E_FILE_TOO_BIG, 
    E_SEEK_OUT_OF_BOUNDS, 
    E_FILE_IN_USE, 
    E_NO_SUCH_DIR, 
    E_DIR_NOT_EMPTY,
    E_ROOT_DIR,
    E_BUFFER_TOO_SMALL, 
} FS_Error_t;
    
// used for errors
extern int osErrno;

// a few file system parameters

// the total number of files and directories in the file system has a
// maximum limit of 1000
#define MAX_FILES 1000

// each file can have a maximum of 30 sectors; we treat the data
// blocks of the file/director the same as sectors
#define MAX_SECTORS_PER_FILE 30

// the size of a file or directory is limited
#define MAX_FILE_SIZE (MAX_SECTORS_PER_FILE*SECTOR_SIZE)

// file system generic calls
int FS_Boot(char *path);
int FS_Sync();

// file ops
int File_Create(char *file);
int File_Open(char *file);
int File_Read(int fd, void *buffer, int size);
int File_Write(int fd, void *buffer, int size);
int File_Seek(int fd, int offset);
int File_Close(int fd);
int File_Unlink(char *file);

// directory ops
int Dir_Create(char *path);
int Dir_Unlink(char *path);
int Dir_Size(char *path);
int Dir_Read(char *path, void *buffer, int size);

#endif /* __LibFS_h__ */
