#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "LibDisk.h"

typedef struct sector {
  char data[SECTOR_SIZE];
} sector_t;

// used to see what happened w/ disk ops
int diskErrno; 

// the disk in memory (static makes it private to the file)
static sector_t* disk;

// used for statistics
// static int lastSector = 0;
// static int seekCount = 0;

/*
 * Disk_Init
 *
 * Initializes the disk area (really just some memory for now).
 *
 * THIS FUNCTION MUST BE CALLED BEFORE ANY OTHER FUNCTION IN HERE CAN BE USED!
 *
 */
int Disk_Init()
{
  // create the disk image and fill every sector with zeroes
  disk = (sector_t *) calloc(TOTAL_SECTORS, sizeof(sector_t));//allocate sector_t in memory
  if(disk == NULL) {
    diskErrno = E_MEM_OP;
    return -1;
  }
  return 0;
}

/*
 * Disk_Save
 *
 * Makes sure the current disk image gets saved to memory - this
 * will overwrite an existing file with the same name so be careful
 */
int Disk_Save(char* file)
{
  FILE* diskFile;
    
  // error check
  if (file == NULL) {
    diskErrno = E_INVALID_PARAM;
    return -1;
  }
    
  // open the diskFile
  if ((diskFile = fopen(file, "w")) == NULL) {
    diskErrno = E_OPENING_FILE;
    return -1;
  }
    
  // actually write the disk image to a file
  if ((fwrite(disk, sizeof(sector_t), TOTAL_SECTORS, diskFile)) != TOTAL_SECTORS) {
    fclose(diskFile);
    diskErrno = E_WRITING_FILE;
    return -1;
  }
    
  // clean up and return
  fclose(diskFile);
  return 0;
}

/*
 * Disk_Load
 *
 * Loads a current disk image from disk into memory - requires that
 * the disk be created first.
 */
int Disk_Load(char* file)
{
  FILE* diskFile;
    
  // error check
  if (file == NULL) {
    diskErrno = E_INVALID_PARAM;
    return -1;
  }
    
  // open the diskFile
  if ((diskFile = fopen(file, "r")) == NULL) {
    diskErrno = E_OPENING_FILE;
    return -1;
  }
    
  // actually read the disk image into memory
  if ((fread(disk, sizeof(sector_t), TOTAL_SECTORS, diskFile)) != TOTAL_SECTORS) {
    fclose(diskFile);
    diskErrno = E_READING_FILE;
    return -1;
  }
    
  // clean up and return
  fclose(diskFile);
  return 0;
}

/*
 * Disk_Read
 *
 * Reads a single sector from "disk" and puts it into a buffer provided
 * by the user.
 */
int Disk_Read(int sector, char* buffer)
{
  // quick error checks
  if ((sector < 0) || (sector >= TOTAL_SECTORS) || (buffer == NULL)) {
    diskErrno = E_INVALID_PARAM;
    return -1;
  }
    
  // copy the memory for the user
  if((memcpy((void*)buffer, (void*)(disk + sector), sizeof(sector_t))) == NULL) {
    diskErrno = E_MEM_OP;
    return -1;
  }
    
  return 0;
}

/*
 * Disk_Write
 *
 * Writes a single sector from memory to "disk".
 */
int Disk_Write(int sector, char* buffer) 
{
  // quick error checks
  if((sector < 0) || (sector >= TOTAL_SECTORS) || (buffer == NULL)) {
    diskErrno = E_INVALID_PARAM;
    return -1;
  }
    
  // copy the memory for the user
  if((memcpy((void*)(disk + sector), (void*)buffer, sizeof(sector_t))) == NULL) {
    diskErrno = E_MEM_OP;
    return -1;
  }
  return 0;
}
