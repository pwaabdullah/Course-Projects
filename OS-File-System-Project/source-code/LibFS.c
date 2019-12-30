// OS file system project
// developed by Abdullah, Vitalli and Sohel aamcse@gmail.com
// Date: Dec 29, 2019
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include "LibDisk.h"
#include "LibFS.h"

// set to 1 to have detailed debug print-outs and 0 to have none
#define FSDEBUG 0

#if FSDEBUG
#define dprintf printf
#else
#define dprintf noprintf
void noprintf(char* str, ...) {}
#endif

// the file system partitions the disk into five parts:

// 1. the superblock (one sector), which contains a magic number at
// its first four bytes (integer)
#define SUPERBLOCK_START_SECTOR 0

// the magic number chosen for our file system
#define OS_MAGIC 0xdeadbeef

// 2. the inode bitmap (one or more sectors), which indicates whether
// the particular entry in the inode table (#4) is currently in use
#define INODE_BITMAP_START_SECTOR 1

// the total number of bytes and sectors needed for the inode bitmap;
// we use one bit for each inode (whether it's a file or directory) to
// indicate whether the particular inode in the inode table is in use
#define INODE_BITMAP_SIZE ((MAX_FILES+7)/8)
#define INODE_BITMAP_SECTORS ((INODE_BITMAP_SIZE+SECTOR_SIZE-1)/SECTOR_SIZE)

// 3. the sector bitmap (one or more sectors), which indicates whether
// the particular sector in the disk is currently in use
#define SECTOR_BITMAP_START_SECTOR (INODE_BITMAP_START_SECTOR+INODE_BITMAP_SECTORS)

// the total number of bytes and sectors needed for the data block
// bitmap (we call it the sector bitmap); we use one bit for each
// sector of the disk to indicate whether the sector is in use or not
#define SECTOR_BITMAP_SIZE ((TOTAL_SECTORS+7)/8)
#define SECTOR_BITMAP_SECTORS ((SECTOR_BITMAP_SIZE+SECTOR_SIZE-1)/SECTOR_SIZE)

// 4. the inode table (one or more sectors), which contains the inodes
// stored consecutively
#define INODE_TABLE_START_SECTOR (SECTOR_BITMAP_START_SECTOR+SECTOR_BITMAP_SECTORS)

// an inode is used to represent each file or directory; the data
// structure supposedly contains all necessary information about the
// corresponding file or directory
typedef struct _inode {
  int size; // the size of the file or number of directory entries
  //int used; // number of dirents written 
  int type; // 0 means regular file; 1 means directory
  int data[MAX_SECTORS_PER_FILE]; // indices to sectors containing data blocks
} inode_t;

// the inode structures are stored consecutively and yet they don't
// straddle accross the sector boundaries; that is, there may be
// fragmentation towards the end of each sector used by the inode
// table; each entry of the inode table is an inode structure; there
// are as many entries in the table as the number of files allowed in
// the system; the inode bitmap (#2) indicates whether the entries are
// current in use or not
#define INODES_PER_SECTOR (SECTOR_SIZE/sizeof(inode_t))
#define INODE_TABLE_SECTORS ((MAX_FILES+INODES_PER_SECTOR-1)/INODES_PER_SECTOR)

// 5. the data blocks; all the rest sectors are reserved for data
// blocks for the content of files and directories
#define DATABLOCK_START_SECTOR (INODE_TABLE_START_SECTOR+INODE_TABLE_SECTORS)

// other file related definitions

// max length of a path is 256 bytes (including the ending null)
#define MAX_PATH 256

// max length of a filename is 16 bytes (including the ending null)
#define MAX_NAME 16

// max number of open files is 256
#define MAX_OPEN_FILES 256

// each directory entry represents a file/directory in the parent
// directory, and consists of a file/directory name (less than 16
// bytes) and an integer inode number
typedef struct _dirent {
  char fname[MAX_NAME]; // name of the file
  int inode; // inode of the file
} dirent_t;

// representing an open file
typedef struct _open_file {
  int inode; // pointing to the inode of the file (0 means entry not used)
  int size;  // file size cached here for convenience
  int pos;   // read/write position
} open_file_t;

// open file table
static open_file_t open_files[MAX_OPEN_FILES];

// the number of directory entries that can be contained in a sector
#define DIRENTS_PER_SECTOR (SECTOR_SIZE/sizeof(dirent_t))

// global errno value here
int osErrno;

// the name of the disk backstore file (with which the file system is booted)
static char bs_filename[1024];

/* the following functions are internal helper functions */

// check magic number in the superblock; return 1 if OK, and 0 if not
static int check_magic() {
  char buf[SECTOR_SIZE];
  if(Disk_Read(SUPERBLOCK_START_SECTOR, buf) < 0)
    return 0;
  if(*(int*)buf == OS_MAGIC)
    return 1;
  else return 0;
}



static void bitmap_init(int start, int num, int nbits){
  int bit, byte, sector;
  
  //initializing 0 in bitmap of every sector
  int flag1 = 1; 
  sector = 0;
  while(sector < num){  
    char buffer_bitmap[SECTOR_SIZE];            // bitmap size (char because each char is equivalent to 1 byte)
    memset(buffer_bitmap, 0, SECTOR_SIZE);      // fill block of memory with 0
    for (byte = 0; byte < SECTOR_SIZE; byte++){ // looping each byte
      if(!flag1) {
        break;
      }
      else {
        for (bit = 7; bit >= 0; bit--){           // looping each bit of every byte
        if (nbits-- > 0){                       // chekcing nbits after decreament by 1
          buffer_bitmap[byte] |= (1 << bit);
          }
        else{
          flag1 = 0;
          break;
          }             // set 1 for first nbits (bitwise OR) for leading the start
        }
      }  
    }
    //update on the disk
    Disk_Write(start+sector, buffer_bitmap);
    sector++;
  }
}


static int bitmap_first_unused(int start, int num, int nbits){
  int id = 0; //starting index is zero by default
  char check_bit_empty; 
  char buffer_bitmap[SECTOR_SIZE];
  int bit, byte, sector;

  // checking every sectors to find the first unused memory
  sector = 0;
  while(sector < num){                          // looping each sector
    Disk_Read(start+sector, buffer_bitmap);     // pull current content
    for (byte = 0; byte < SECTOR_SIZE; byte++){ // looping each byte
      for (bit = 7; bit >= 0; bit--){           // looping every bit
        check_bit_empty = (buffer_bitmap[byte] >> bit) & 1; // Shift and ANDing for knowing which bits are still high
                            
        if (check_bit_empty == 0){              // if used bit found, set it to 0
          buffer_bitmap[byte] |= 1 << bit;
          Disk_Write(start+sector, buffer_bitmap); // update the disk
          return id;                               // return index   
        }
        id++;
        if (id > nbits){        // return -1 if the index exceed the maximum number of bitmaps
          return -1;   
        }                       // increament index by 1
      }
    }
    sector++;
  }
  return -1;                                    // return -1 if first unsused not found
}

//reset the i-th bit of a bitmap with 'num' sectors starting from
//'start' sector; return 0 if successful, -1 otherwise
static int bitmap_reset(int start, int num, int ibit) {
   char buffer_bitmap[SECTOR_SIZE];
   int bit, byte, sector;

   // loop through each sector in bitmap 
   sector = 0;
    while(sector < num){
     Disk_Read(start+sector, buffer_bitmap);
     for (byte = 0; byte < SECTOR_SIZE; byte++){  // checking every byte
       for(bit = 7; bit >= 0; bit--){             // checking every bit
         if(!ibit){                               // once our bit is found set to 0 and write changes
           buffer_bitmap[byte] &= ~(1 << bit);    // Left shift NOT of 1 then AND to set 0
           Disk_Write(start+sector, buffer_bitmap);
           return 0;
         }
         ibit--;
       }
     }
     sector++;
   }
   return -1;
 }



static int illegal_filename(char* name) {
  int i;
  char end[] = "-_.";
  
  //checking character by character 
  for(i = 0; i < strlen(name); i++){
    if(!isdigit(name[i]) && !isalpha(name[i]) && !strchr(end, name[i])){
      printf("Illegal character found! %c\n", name[i]);
      return 1;
    }
  }

  //checking length
  if(strlen(name) >= MAX_NAME-1){
    printf("Bad Length\n");
    return 1;
  }

  //return false otherwise
  return 0;
}




int remove_inode(int type, int parent_inode, int child_inode)
{
  // This function is a modification to add_inode() that removes child inode
  dprintf("... removing inode %d\n", child_inode);
  //----------------------------------------------------------------------------------------------
  // Load Child iNode from the disk
  //----------------------------------------------------------------------------------------------
  // load the disk sector containing the child inode
  int inode_sector = INODE_TABLE_START_SECTOR+child_inode/INODES_PER_SECTOR;
  char inode_buffer[SECTOR_SIZE];
  if(Disk_Read(inode_sector, inode_buffer) < 0){
    dprintf("Error: can't read inode from disk sector");
    return -1;
  }
  //dprintf("%s\n", inode_buffer);
  dprintf("... load inode table for child inode from disk sector %d\n", inode_sector);

  // get the child inode
  int inode_start_entry = (inode_sector-INODE_TABLE_START_SECTOR)*INODES_PER_SECTOR;
  int offset = child_inode-inode_start_entry;
  assert(0 <= offset && offset < INODES_PER_SECTOR);
  inode_t* child = (inode_t*)(inode_buffer+offset*sizeof(inode_t));

  //----------------------------------------------------------------------------------------------
  // Check for errors
  //----------------------------------------------------------------------------------------------
  // Check if the type is right
  if(child->type != type){
    dprintf("Error: the actual type of inode doesn't match with parameter specified in function remove_inode()");
    return -3;
  }

  //Check if directory is not empty
  if(child->type==1 && child->size!=0){
    dprintf("Error: directory is not empty");
    osErrno = E_DIR_NOT_EMPTY;
    return -2;
  }
  //----------------------------------------------------------------------------------------------
  // Remove the file content from the disk
  //----------------------------------------------------------------------------------------------
  char buf_sector[SECTOR_SIZE];
  int sector_address;
  if(child->size>0){
    dprintf("%s\n", "... Removing file data from the disk");
    for(int i; i<MAX_SECTORS_PER_FILE; i++){
      sector_address = child->data[i];
      if(sector_address>0){
        //remove from sector
        if(Disk_Read(sector_address, buf_sector)<0) return -1; //try to read the sector
        memset(buf_sector, 0, SECTOR_SIZE);//set buffer to 0
        Disk_Write(sector_address, buf_sector); //write 0s to the sector
        bitmap_reset(SECTOR_BITMAP_START_SECTOR, SECTOR_BITMAP_SECTORS, sector_address);//reset bitmap for the current sector
      }
    }
  } else{
    dprintf("%s\n", "... The directory/file is empty");
  }
  //----------------------------------------------------------------------------------------------
  // Remove iNode from the disk sector
  //----------------------------------------------------------------------------------------------
  dprintf("%s\n", "... Removing inode from the disk");
  memset(child, 0, sizeof(inode_t)); //Delete child inodes from memory
 // memset(inode_buffer, 0, SECTOR_SIZE);
  if(Disk_Write(inode_sector, inode_buffer)<0) return -1;
  //----------------------------------------------------------------------------------------------
  // Reset iNode bitmap
  //----------------------------------------------------------------------------------------------
  bitmap_reset(INODE_BITMAP_START_SECTOR, INODE_BITMAP_SECTORS, child_inode); //reset i-node bitmap
  // Remove link from parent inode to child inode
  //----------------------------------------------------------------------------------------------
  // Read the parent iNode from the disk
  //----------------------------------------------------------------------------------------------
  // get the disk sector containing the parent inode
  inode_sector = INODE_TABLE_START_SECTOR+parent_inode/INODES_PER_SECTOR;
  if(Disk_Read(inode_sector, inode_buffer) < 0) return -1;
  dprintf("... load inode table for parent inode %d from disk sector %d\n",
   parent_inode, inode_sector);

  // get the parent inode
  inode_start_entry = (inode_sector-INODE_TABLE_START_SECTOR)*INODES_PER_SECTOR;
  offset = parent_inode-inode_start_entry;
  assert(0 <= offset && offset < INODES_PER_SECTOR);
  inode_t* parent = (inode_t*)(inode_buffer+offset*sizeof(inode_t));
  dprintf("... get parent inode %d (size=%d, type=%d)\n",
   parent_inode, parent->size, parent->type);
  //----------------------------------------------------------------------------------------------
  // Check if parent iNode is a directory
  //----------------------------------------------------------------------------------------------
  if(parent->type != 1){
    dprintf("... error: parent inode is not directory\n");
    return -2;
  }
  //----------------------------------------------------------------------------------------------
  // Update parent iNode and dirent table
  //----------------------------------------------------------------------------------------------
  int nentries = parent->size; // remaining number of directory entries 
  int idx = 0;
  int found_flag=0;
  while(nentries > 0) {
    char dirent_buffer[SECTOR_SIZE]; // cached content of directory entries
    if(Disk_Read(parent->data[idx], dirent_buffer) < 0) return -2;
    for(int i=0; i<DIRENTS_PER_SECTOR; i++) {
    if(i>nentries) break;
    dirent_t* tmp_dirent = (dirent_t*)(dirent_buffer +i*sizeof(dirent_t));
    
    if(tmp_dirent->inode==child_inode){//dirent found
          dprintf("... Corresponding dirent found\n");
          char dirent_buffer2[SECTOR_SIZE];

          int group = parent->size/DIRENTS_PER_SECTOR;
          if(Disk_Read(parent->data[group], dirent_buffer2) < 0) return -2;
          int start_entry = group*DIRENTS_PER_SECTOR;
          offset = parent->size-start_entry;
          dirent_t* tmp_dirent1 = (dirent_t*)(dirent_buffer2+offset*sizeof(dirent_t));
          
          strncpy(tmp_dirent->fname, tmp_dirent1->fname, MAX_NAME);
          tmp_dirent->inode = tmp_dirent1->inode;
          memset(tmp_dirent1, 0, sizeof(dirent_t));
          parent->size--;
          if(Disk_Write(inode_sector, inode_buffer)<0) return -1;//update parent inode
          if(Disk_Write(parent->data[group], dirent_buffer2)) return -1;//update dirent
          if(Disk_Write(parent->data[idx], dirent_buffer)) return -1;//update dirent
          found_flag=1;
    }
    } 
    idx++; nentries -= DIRENTS_PER_SECTOR;
  }
  if(found_flag==1) return 0;
  else{
  dprintf("... could not find dirent\n");
  return -1; // not found
  }
}

// return the child inode of the given file name 'fname' from the
// parent inode; the parent inode is currently stored in the segment
// of inode table in the cache (we cache only one disk sector for
// this); once found, both cached_inode_sector and cached_inode_buffer
// may be updated to point to the segment of inode table containing
// the child inode; the function returns -1 if no such file is found;
// it returns -2 is something else is wrong (such as parent is not
// directory, or there's read error, etc.)
static int find_child_inode(int parent_inode, char* fname, int *cached_inode_sector, char* cached_inode_buffer) {
  int cached_start_entry = ((*cached_inode_sector)-INODE_TABLE_START_SECTOR)*INODES_PER_SECTOR;
  int offset = parent_inode-cached_start_entry;
  assert(0 <= offset && offset < INODES_PER_SECTOR);
  inode_t* parent = (inode_t*)(cached_inode_buffer+offset*sizeof(inode_t));
  dprintf("... load parent inode: %d (size=%d, type=%d)\n", parent_inode, parent->size, parent->type);
  if(parent->type != 1) {
    dprintf("... parent not a directory\n");
    return -2;
  }
  
  int nentries = parent->size; // remaining number of directory entries 
  int idx = 0;
  while(nentries > 0) {
    char buf[SECTOR_SIZE]; // cached content of directory entries
    if(Disk_Read(parent->data[idx], buf) < 0) return -2;
    int i;
    for(i=0; i<DIRENTS_PER_SECTOR; i++) {
      if(i>nentries) break;
      if(!strcmp(((dirent_t*)buf)[i].fname, fname)) {
        // found the file/directory; update inode cache
        int child_inode = ((dirent_t*)buf)[i].inode;
        dprintf("... found child_inode=%d\n", child_inode);
        int sector = INODE_TABLE_START_SECTOR+child_inode/INODES_PER_SECTOR;
        if(sector != (*cached_inode_sector)) {
          *cached_inode_sector = sector;
          if(Disk_Read(sector, cached_inode_buffer) < 0)
            return -2;
          dprintf("... load inode table for child\n");
        }
        return child_inode;
      }
    }
    idx++; nentries -= DIRENTS_PER_SECTOR;
  }
  dprintf("... could not find child inode\n");
  return -1; // not found
}

// follow the absolute path; if successful, return the inode of the
// parent directory immediately before the last file/directory in the
// path; for example, for '/a/b/c/d.txt', the parent is '/a/b/c' and
// the child is 'd.txt'; the child's inode is returned through the
// parameter 'last_inode' and its file name is returned through the
// parameter 'last_fname' (both are references); it's possible that
// the last file/directory is not in its parent directory, in which
// case, 'last_inode' points to -1; if the function returns -1, it
// means that we cannot follow the path
static int follow_path(char* path, int* last_inode, char* last_fname) {
  if(!path) {
    printf("... invalid path\n");
    return -1;
  }
  if(path[0] != '/') {
    printf("... '%s' not absolute path\n", path);
    return -1;
  }
  
  // make a copy of the path (skip leading '/'); this is necessary
  // since the path is going to be modified by strsep()
  char pathstore[MAX_PATH]; 
  strncpy(pathstore, path+1, MAX_PATH-1);
  pathstore[MAX_PATH-1] = '\0'; // for safety
  char* lpath = pathstore;
  int parent_inode = -1, child_inode = 0; // start from root
  
  // cache the disk sector containing the root inode
  int cached_sector = INODE_TABLE_START_SECTOR;
  char cached_buffer[SECTOR_SIZE];
  if(Disk_Read(cached_sector, cached_buffer) < 0) return -1;
  dprintf("... load inode table for root from disk sector %d\n", cached_sector);
  
  // for each file/directory name separated by '/'
  char* token;
  while((token = strsep(&lpath, "/")) != NULL) {
    dprintf("... process token: '%s'\n", token);
    if(*token == '\0')
      continue; // multiple '/' ignored
    if(illegal_filename(token)) {
      dprintf("... illegal file name: '%s'\n", token);
      return -1;
    }
    if(child_inode < 0) {
      // regardless whether child_inode was not found previously, or
      // there was issues related to the parent (say, not a
      // directory), or there was a read error, we abort
      dprintf("... parent inode can't be established\n");
      return -1;
    }
    parent_inode = child_inode;
    child_inode = find_child_inode(parent_inode, token, &cached_sector, cached_buffer);
    if(last_fname)
      strcpy(last_fname, token);
  }
  if(child_inode < -1){
    return -1; // if there was error, abort
  }
  else {
    // there was no error, several possibilities:
    // 1) '/': parent = -1, child = 0
    // 2) '/valid-dirs.../last-valid-dir/not-found': parent=last-valid-dir, child=-1
    // 3) '/valid-dirs.../last-valid-dir/found: parent=last-valid-dir, child=found
    // in the first case, we set parent=child=0 as special case
    if(parent_inode==-1 && child_inode==0)
      parent_inode = 0;
    dprintf("... found parent_inode=%d, child_inode=%d\n", parent_inode, child_inode);
    *last_inode = child_inode;
    return parent_inode;
  }
}

// add a new file or directory (determined by 'type') of given name
// 'file' under parent directory represented by 'parent_inode'
int add_inode(int type, int parent_inode, char* file) {
  // get a new inode for child
  int child_inode = bitmap_first_unused(INODE_BITMAP_START_SECTOR, INODE_BITMAP_SECTORS, INODE_BITMAP_SIZE);
  if(child_inode < 0) {
    dprintf("... error: inode table is full\n");
    return -1; 
  }
  dprintf("... new child inode %d\n", child_inode);
  
  // load the disk sector containing the child inode
  int inode_sector = INODE_TABLE_START_SECTOR+child_inode/INODES_PER_SECTOR;
  char inode_buffer[SECTOR_SIZE];
  if(Disk_Read(inode_sector, inode_buffer) < 0)
    return -1;
  dprintf("... load inode table for child inode from disk sector %d\n", inode_sector);
  
  // get the child inode
  int inode_start_entry = (inode_sector-INODE_TABLE_START_SECTOR)*INODES_PER_SECTOR;
  int offset = child_inode-inode_start_entry;
  assert(0 <= offset && offset < INODES_PER_SECTOR);
  inode_t* child = (inode_t*)(inode_buffer+offset*sizeof(inode_t));
  
  // update the new child inode and write to disk
  memset(child, 0, sizeof(inode_t));
  child->type = type;
  if(Disk_Write(inode_sector, inode_buffer) < 0)
    return -1;
  dprintf("... update child inode %d (size=%d, type=%d), update disk sector %d\n", child_inode, child->size, child->type, inode_sector);
  
  // get the disk sector containing the parent inode
  inode_sector = INODE_TABLE_START_SECTOR+parent_inode/INODES_PER_SECTOR;
  if(Disk_Read(inode_sector, inode_buffer) < 0)
    return -1;
  dprintf("... load inode table for parent inode %d from disk sector %d\n", parent_inode, inode_sector);
  
  // get the parent inode
  inode_start_entry = (inode_sector-INODE_TABLE_START_SECTOR)*INODES_PER_SECTOR;
  offset = parent_inode-inode_start_entry;
  assert(0 <= offset && offset < INODES_PER_SECTOR);
  inode_t* parent = (inode_t*)(inode_buffer+offset*sizeof(inode_t));
  dprintf("... get parent inode %d (size=%d, type=%d)\n", parent_inode, parent->size, parent->type);
  
  // get the dirent sector
  if(parent->type != 1) {
    dprintf("... error: parent inode is not directory\n");
    return -2; // parent not directory
  }
  int group = parent->size/DIRENTS_PER_SECTOR;
  char dirent_buffer[SECTOR_SIZE];
  if(group*DIRENTS_PER_SECTOR == parent->size) {
    // new disk sector is needed
    int newsec = bitmap_first_unused(SECTOR_BITMAP_START_SECTOR, SECTOR_BITMAP_SECTORS, SECTOR_BITMAP_SIZE);
    if(newsec < 0) {
      dprintf("... error: disk is full\n");
      return -1;
    }
    parent->data[group] = newsec;
    memset(dirent_buffer, 0, SECTOR_SIZE);
    dprintf("... new disk sector %d for dirent group %d\n", newsec, group);
  }
  else {
    if(Disk_Read(parent->data[group], dirent_buffer) < 0)
      return -1;
    dprintf("... load disk sector %d for dirent group %d\n", parent->data[group], group);
  }
  
  // add the dirent and write to disk
  int start_entry = group*DIRENTS_PER_SECTOR;
  offset = parent->size-start_entry;
  dirent_t* dirent = (dirent_t*)(dirent_buffer+offset*sizeof(dirent_t));
  strncpy(dirent->fname, file, MAX_NAME);
  dirent->inode = child_inode;
  if(Disk_Write(parent->data[group], dirent_buffer) < 0)
    return -1;
  dprintf("... append dirent %d (name='%s', inode=%d) to group %d, update disk sector %d\n", parent->size, dirent->fname, dirent->inode, group, parent->data[group]);
  
  // update parent inode and write to disk
  parent->size++;
  parent->size++;
  if(Disk_Write(inode_sector, inode_buffer) < 0)
    return -1;
  dprintf("... update parent inode on disk sector %d\n", inode_sector);
  return 0;
}

// size by both File_Create() and Dir_Create(); type=0 is file, type=1
// is directory
int create_file_or_directory(int type, char* pathname) {
  int child_inode;
  char last_fname[MAX_NAME];
  int parent_inode = follow_path(pathname, &child_inode, last_fname);
  if(parent_inode >= 0) {
    if(child_inode >= 0) {
      dprintf("... file/directory '%s' already exists, failed to create\n", pathname);
      osErrno = E_CREATE;
      return -1;
    }
    else {
      if(add_inode(type, parent_inode, last_fname) >= 0) {
        dprintf("... successfully created file/directory: '%s'\n", pathname);
        return 0;
      }
      else {
        dprintf("... error: something wrong with adding child inode\n");
        osErrno = E_CREATE;
        return -1;
      }
    }
  }
  else {
    dprintf("... error: something wrong with the file/path: '%s'\n", pathname);
    osErrno = E_CREATE;
    return -1;
  }
}

// return true if the file pointed to by inode has already been open
int is_file_open(int inode) {
  int i;
  for(i = 0; i<MAX_OPEN_FILES; i++) {
    if(open_files[i].inode == inode)
      return 1;
  }
  return 0;
}


/* YOUR CODE */
int remove_file_or_directory(int type, char* pathname)
{
  //type=0 -file
  //type=1 - directory
  // This function is modification of create_file_or_directory() that removes file or directory

  int child_inode;
  char last_fname[MAX_NAME];
  int parent_inode = follow_path(pathname, &child_inode, last_fname);
  if(parent_inode >= 0) {
   //----------------------------------------------------------------
  // return error if there are no such files
  //----------------------------------------------------------------
    if(child_inode < 0) {
      dprintf("... file/directory '%s' doesn't exist \n", pathname);
      if(type==0) {
      osErrno = E_NO_SUCH_FILE;
      } else{
        osErrno = E_NO_SUCH_DIR;
      }
      return -1;
    } else {
  //----------------------------------------------------------------
  // Return error if file is currently open
  //---------------------------------------
        if(type==0 && is_file_open(child_inode)){
          osErrno = E_FILE_IN_USE;
          return -1;
   //----------------------------------------------------------------
  // Remove iNode
  //----------------------------------------------------------------
      } else if(remove_inode(type, parent_inode, child_inode) >= 0){
          dprintf("... successfully removed file/directory: '%s'\n", pathname);
          return 0;
  //----------------------------------------------------------------
  // Return error if child inode couldn't be removed
  //----------------------------------------------------------------
      } else {
          dprintf("... error: something wrong with removing file/directory\n");
          osErrno = E_NO_SUCH_FILE;
          return -1;
      }
    }
  }else{
  //----------------------------------------------------------------
  // Return error if can't find parent iNode
  //----------------------------------------------------------------
    if(type==0){
      osErrno = E_NO_SUCH_FILE;
    }else{
      osErrno = E_NO_SUCH_DIR;
    }
    return -1;
  }
}

// return a new file descriptor not used; -1 if full
int new_file_fd() {
  int i;
  for(i=0; i<MAX_OPEN_FILES; i++) {
    if(open_files[i].inode <= 0)
      return i;
  }
  return -1;
}

/* end of internal helper functions, start of API functions */

int FS_Boot(char* backstore_fname) {
  dprintf("FS_Boot('%s'):\n", backstore_fname);
  // initialize a new disk (this is a simulated disk)
  if(Disk_Init() < 0) {
    dprintf("... disk init failed\n");
    osErrno = E_GENERAL;
    return -1;
  }
  dprintf("... disk initialized\n");
  
  // we should copy the filename down; if not, the user may change the
  // content pointed to by 'backstore_fname' after calling this function
  strncpy(bs_filename, backstore_fname, 1024);
  bs_filename[1023] = '\0'; // for safety
  
  // we first try to load disk from this file
  if(Disk_Load(bs_filename) < 0) {
    dprintf("... load disk from file '%s' failed\n", bs_filename);
    
    // if we can't open the file; it means the file does not exist, we
    // need to create a new file system on disk
    if(diskErrno == E_OPENING_FILE) {
      dprintf("... couldn't open file, create new file system\n");
      
      // format superblock
      char buf[SECTOR_SIZE];
      memset(buf, 0, SECTOR_SIZE);
      *(int*)buf = OS_MAGIC;
      if(Disk_Write(SUPERBLOCK_START_SECTOR, buf) < 0) {
        dprintf("... failed to format superblock\n");
        osErrno = E_GENERAL;
        return -1;
      }
      dprintf("... formatted superblock (sector %d)\n", SUPERBLOCK_START_SECTOR);
      
      // format inode bitmap (reserve the first inode to root)
      bitmap_init(INODE_BITMAP_START_SECTOR, INODE_BITMAP_SECTORS, 1);
      dprintf("... formatted inode bitmap (start=%d, num=%d)\n", (int)INODE_BITMAP_START_SECTOR, (int)INODE_BITMAP_SECTORS);
      
      // format sector bitmap (reserve the first few sectors to
      // superblock, inode bitmap, sector bitmap, and inode table)
      bitmap_init(SECTOR_BITMAP_START_SECTOR, SECTOR_BITMAP_SECTORS, DATABLOCK_START_SECTOR);
      dprintf("... formatted sector bitmap (start=%d, num=%d)\n", (int)SECTOR_BITMAP_START_SECTOR, (int)SECTOR_BITMAP_SECTORS);
      
      // format inode tables
      int i;
      for(i=0; i<INODE_TABLE_SECTORS; i++) {
        memset(buf, 0, SECTOR_SIZE);
        if(i==0) {
          // the first inode table entry is the root directory
          ((inode_t*)buf)->size = 0;
          ((inode_t*)buf)->type = 1;
        }
        if(Disk_Write(INODE_TABLE_START_SECTOR+i, buf) < 0) {
          dprintf("... failed to format inode table\n");
          osErrno = E_GENERAL;
          return -1;
        }
      }
      dprintf("... formatted inode table (start=%d, num=%d)\n", (int)INODE_TABLE_START_SECTOR, (int)INODE_TABLE_SECTORS);
      
      // we need to synchronize the disk to the backstore file (so
      // that we don't lose the formatted disk)
      if(Disk_Save(bs_filename) < 0) {
        // if can't write to file, something's wrong with the backstore
        dprintf("... failed to save disk to file '%s'\n", bs_filename);
        osErrno = E_GENERAL;
        return -1;
      }
      else {
        // everything's good now, boot is successful
        dprintf("... successfully formatted disk, boot successful\n");
        memset(open_files, 0, MAX_OPEN_FILES*sizeof(open_file_t));
        return 0;
      }
    }
    else {
      // something wrong loading the file: invalid param or error reading
      dprintf("... couldn't read file '%s', boot failed\n", bs_filename);
      osErrno = E_GENERAL;
      return -1;
    }
  }
  else {
    dprintf("... load disk from file '%s' successful\n", bs_filename);
    
    // we successfully loaded the disk, we need to do two more checks,
    // first the file size must be exactly the size as expected (thiis
    // supposedly should be folded in Disk_Load(); and it's not)
    int sz = 0;
    FILE* f = fopen(bs_filename, "r");
    if(f) {
      fseek(f, 0, SEEK_END);
      sz = ftell(f);
      fclose(f);
    }
    if(sz != SECTOR_SIZE*TOTAL_SECTORS) {
      dprintf("... check size of file '%s' failed\n", bs_filename);
      osErrno = E_GENERAL;
      return -1;
    }
    dprintf("... check size of file '%s' successful\n", bs_filename);
    
    // check magic
    if(check_magic()) {
      // everything's good by now, boot is successful
      dprintf("... check magic successful\n");
      memset(open_files, 0, MAX_OPEN_FILES*sizeof(open_file_t));
      return 0;
    }
    else {
      // mismatched magic number
      dprintf("... check magic failed, boot failed\n");
      osErrno = E_GENERAL;
      return -1;
    }
  }
}

int FS_Sync() {
  if(Disk_Save(bs_filename) < 0) {
    // if can't write to file, something's wrong with the backstore
    dprintf("FS_Sync():\n... failed to save disk to file '%s'\n", bs_filename);
    osErrno = E_GENERAL;
    return -1;
  }
  else {
    // everything's good now, sync is successful
    dprintf("FS_Sync():\n... successfully saved disk to file '%s'\n", bs_filename);
    return 0;
  }
}

int File_Create(char* file) {
  dprintf("File_Create('%s'):\n", file);
  return create_file_or_directory(0, file);
}



/* YOUR CODE */
int File_Unlink(char* file){
  dprintf("File_Unlink('%s'):\n", file);
  return remove_file_or_directory(0, file);
}

int File_Open(char* file) {
  dprintf("File_Open('%s'):\n", file);
  int fd = new_file_fd();
  if(fd < 0) {
    dprintf("... max open files reached\n");
    osErrno = E_TOO_MANY_OPEN_FILES;
    return -1;
  }
  
  int child_inode;
  follow_path(file, &child_inode, NULL);
  if(child_inode >= 0) { // child is the one
    // load the disk sector containing the inode
    int inode_sector = INODE_TABLE_START_SECTOR+child_inode/INODES_PER_SECTOR;
    char inode_buffer[SECTOR_SIZE];
    if(Disk_Read(inode_sector, inode_buffer) < 0) {
      osErrno = E_GENERAL;
      return -1;
    }
    dprintf("... load inode table for inode from disk sector %d\n", inode_sector);
    
    // get the inode
    int inode_start_entry = (inode_sector-INODE_TABLE_START_SECTOR)*INODES_PER_SECTOR;
    int offset = child_inode-inode_start_entry;
    assert(0 <= offset && offset < INODES_PER_SECTOR);
    inode_t* child = (inode_t*)(inode_buffer+offset*sizeof(inode_t));
    dprintf("... inode %d (size=%d, type=%d)\n", child_inode, child->size, child->type);
    
    if(child->type != 0) {
      dprintf("... error: '%s' is not a file\n", file);
      osErrno = E_GENERAL;
      return -1;
    }
    
    // initialize open file entry and return its index
    open_files[fd].inode = child_inode;
    open_files[fd].size = child->size;
    open_files[fd].pos = 0;
    return fd;
  }
  else {
    dprintf("... file '%s' is not found\n", file);
    osErrno = E_NO_SUCH_FILE;
    return -1;
  }
}


/* YOUR CODE */
int File_Read(int fd, void* buffer, int size)
{ 
  int reading_part = 0; // File is read and kept a copy into reading_part

  open_file_t openFileInfo = open_files[fd]; // Information about the file fd
  
  // First check the file is open or not
  if (openFileInfo.inode == 0) 
  {
      dprintf("...file not open");
      osErrno = E_BAD_FD;
      return -1; 
  }

  // load the disk sector containing the inode
  int inode_sector = INODE_TABLE_START_SECTOR+ openFileInfo.inode/INODES_PER_SECTOR;
  char inode_buffer[SECTOR_SIZE];
  if(Disk_Read(inode_sector, inode_buffer) < 0) {
    osErrno = E_GENERAL;
    return -1;
  }
  dprintf("... load inode table for inode from disk sector %d\n", inode_sector);

  // get the inode
  int inode_start_entry = (inode_sector - INODE_TABLE_START_SECTOR) * INODES_PER_SECTOR;
  int offset = openFileInfo.inode - inode_start_entry;
  assert(0 <= offset && offset < INODES_PER_SECTOR);
  inode_t *child_inode = (inode_t *) (inode_buffer + offset * sizeof(inode_t));


  int sector_read = openFileInfo.pos / SECTOR_SIZE; // The sector which need to read

  // Check if the position is at the end of file, or data at that sector does not exists
  if (openFileInfo.pos == MAX_FILE_SIZE || !child_inode->data[sector_read]) { 
    return 0; 
  } 
  
  char sectorBuffer[SECTOR_SIZE];
  // check if the there any problem to read the data
  if (Disk_Read(child_inode->data[sector_read], sectorBuffer) < 0) { 
    return -1; 
  }
  dprintf("... load disk sector %d\n", child_inode->data[sector_read]);


  void *reading_pos = sectorBuffer + (open_files[fd].pos - (openFileInfo.pos / SECTOR_SIZE) * SECTOR_SIZE);

  // Read the data from the file unlit maximum file is already read completely or
  // requeased read size is already read or all the data has been accessed
  while (open_files[fd].pos < MAX_FILE_SIZE && size > 0 && child_inode->data[sector_read]) {

      if (size >= SECTOR_SIZE) {
          dprintf("... Reading BYTE  %d\n", open_files[fd].pos);
          memcpy(buffer, reading_pos, SECTOR_SIZE);
          size -= SECTOR_SIZE;
          buffer += SECTOR_SIZE;
          reading_part += SECTOR_SIZE;
          open_files[fd].pos += SECTOR_SIZE;
          sector_read++;
          if (open_files[fd].pos < MAX_FILE_SIZE) { // check if file read reach to maximum file size
              if (Disk_Read(child_inode->data[sector_read], sectorBuffer) < 0) { 
                return -1; 
              }
              reading_pos = sectorBuffer;
          } else { 
            return reading_part; 
          }

      } else {
          dprintf("... Reading BYTE  %d\n", open_files[fd].pos);
          memcpy(buffer, reading_pos, (size_t) size);
          reading_part += size;
          open_files[fd].pos += size;
          return reading_part;
      }
  }
  return reading_part;
  //return -1;
}


/* YOUR CODE */
int File_Write(int fd, void* buffer, int size){

  int remaining_writing = size;
  
  // Have the information about the file (fd) where we have to write the buffer
  open_file_t openFileInfo = open_files[fd]; 
  
  // First check the file is open or not
  if (openFileInfo.inode == 0) {
      dprintf("... file not open");
      osErrno = E_BAD_FD;    // if not open set the osError to E_BAD_FD
      return -1;
  }
  
  // check if the file have enough space to write 
  if ((openFileInfo.size + size) > MAX_FILE_SIZE) {
      dprintf("... file is too big.");
      osErrno = E_FILE_TOO_BIG;  
      return -1;
  }

  // load the disk sector containing the inode
  int inode_sector = INODE_TABLE_START_SECTOR+ openFileInfo.inode/INODES_PER_SECTOR;
  char inode_buffer[SECTOR_SIZE];
  if(Disk_Read(inode_sector, inode_buffer) < 0) {
    osErrno = E_GENERAL;
    return -1;
  }
  dprintf("... load inode table for inode from disk sector %d\n", inode_sector);

  // get the inode
  int inode_start_entry = (inode_sector - INODE_TABLE_START_SECTOR) * INODES_PER_SECTOR;
  int offset = openFileInfo.inode - inode_start_entry;
  assert(0 <= offset && offset < INODES_PER_SECTOR);
  inode_t *fileInode = (inode_t *) (inode_buffer + offset * sizeof(inode_t));

  int sectors_need = (size / SECTOR_SIZE) + 1; // number of sectors needed to write the buffer

  // start the process of writting
  for (int i = 0; i < sectors_need; i++) {
      char sector[SECTOR_SIZE];
      int sector_ID = bitmap_first_unused(SECTOR_BITMAP_START_SECTOR, SECTOR_BITMAP_SECTORS, SECTOR_BITMAP_SIZE);

      // Check if there is any sector left for writing
      if (sector_ID < 0) {
          osErrno = E_NO_SPACE;
          dprintf("... no space left.");
          Disk_Write(INODE_TABLE_START_SECTOR + (openFileInfo.inode / INODES_PER_SECTOR), inode_buffer);
          return -1;
      }
      fileInode->data[i] = sector_ID;
      Disk_Read(sector_ID, sector);

      // write buffer to sector. Buffer might be bigger than sector
      // need to request more sectors
      if (remaining_writing > SECTOR_SIZE) {
          remaining_writing -= SECTOR_SIZE;
          memcpy(sector, buffer, SECTOR_SIZE);
          buffer += SECTOR_SIZE;
          fileInode->size += SECTOR_SIZE;
      } else {
          memcpy(sector, buffer, (size_t) remaining_writing);
          buffer += remaining_writing;
          fileInode->size += remaining_writing;
          remaining_writing = 0;
      }
      openFileInfo.size = fileInode->size;
      openFileInfo.pos = fileInode->size;
      Disk_Write(sector_ID, sector);
  }
  Disk_Write(INODE_TABLE_START_SECTOR + (openFileInfo.inode / INODES_PER_SECTOR), inode_buffer);
  return size - remaining_writing;
}


/* YOUR CODE */
int File_Seek(int fd, int offset){
  open_file_t openFileInfo = open_files[fd];
  
  if (openFileInfo.inode == 0) { // check if the file is open or not
      dprintf("... file not open");
      osErrno = E_BAD_FD;
      return -1;
  }

  //Check if offset is larger than the size of the file or offset is negative
  if (offset > openFileInfo.size || offset < 0) {
      dprintf("... offset is out of bound");
      osErrno = E_SEEK_OUT_OF_BOUNDS;
      return -1;
  }

  open_files[fd].pos = offset;
  return open_files[fd].pos;
}

int File_Close(int fd) {\
  dprintf("File_Close(%d):\n", fd);
  if(0 > fd || fd > MAX_OPEN_FILES) {
    dprintf("... fd=%d out of bound\n", fd);
    osErrno = E_BAD_FD;
    return -1;
  }
  
  if(open_files[fd].inode <= 0) {
    dprintf("... fd=%d not an open file\n", fd);
    osErrno = E_BAD_FD;
    return -1;
  }
  
  dprintf("... file closed successfully\n");
  open_files[fd].inode = 0;
  return 0;
}

int Dir_Create(char* path) {
  dprintf("Dir_Create('%s'):\n", path);
  return create_file_or_directory(1, path);
}



/* YOUR CODE */
int Dir_Unlink(char* path)
{
  dprintf("Dir_Unlink('%s'):\n", path);
  return remove_file_or_directory(1, path);
}


/* YOUR CODE */
int Dir_Size(char* path){
  int parent_inode; //inode of the directory that need to read 
  follow_path(path, &parent_inode, NULL);

  if (parent_inode >= 0) { //check the directory is found or not 

    // load the disk sector containing the inode
    int inode_sector = INODE_TABLE_START_SECTOR+parent_inode/INODES_PER_SECTOR;
    char inode_buffer[SECTOR_SIZE];
    if(Disk_Read(inode_sector, inode_buffer) < 0) {
      osErrno = E_GENERAL;
      return -1;
    }
    dprintf("... load inode table for inode from disk sector %d\n", inode_sector);


    // get the inode
    int inode_start_entry = (inode_sector - INODE_TABLE_START_SECTOR) * INODES_PER_SECTOR;
    int offset = parent_inode - inode_start_entry;
    assert(0 <= offset && offset < INODES_PER_SECTOR);
    inode_t *directory_inode = (inode_t *) (inode_buffer + offset * sizeof(inode_t));
    dprintf("... inode %d (size=%d, type=%d)\n", parent_inode, directory_inode->size, directory_inode->type);

    // cheack weather the inode type is directory 
    if (directory_inode->type != 1) {
        dprintf("... error: '%s' is not a directory\n", path);
        osErrno = E_GENERAL;
        return -1;
    }
    dprintf("... RETURNING SIZE: '%d' \n", (int) (directory_inode->size * sizeof(dirent_t)));

    return (int) (directory_inode->size * sizeof(dirent_t));
  } else {
      dprintf("... directory '%s' is not found\n", path);
      return 0;
  }
}

/* YOUR CODE */
int Dir_Read(char* path, void* buffer, int size) {
  int parent_inode; //inode of the directory that need to read 
  follow_path(path, &parent_inode, NULL);

  if (parent_inode >= 0) { //check the directory is found or not 
    // load the disk sector containing the inode
    int inode_sector = INODE_TABLE_START_SECTOR+parent_inode/INODES_PER_SECTOR;
    char inode_buffer[SECTOR_SIZE];
    if(Disk_Read(inode_sector, inode_buffer) < 0) {
      osErrno = E_GENERAL;
      return -1;
    }
    dprintf("... load inode table for inode from disk sector %d\n", inode_sector);
    
    
    // get the  inode
    int inode_start_entry = (inode_sector-INODE_TABLE_START_SECTOR)*INODES_PER_SECTOR;
    int offset = parent_inode-inode_start_entry;
    assert(0 <= offset && offset < INODES_PER_SECTOR);
    inode_t* directory_inode = (inode_t*)(inode_buffer+offset*sizeof(inode_t));
    dprintf("... inode %d (size=%d, type=%d)\n", parent_inode, directory_inode->size, directory_inode->type);


    // cheack weather the inode type is directory 
    if(directory_inode->type != 1) {
      dprintf("... error: '%s' is not a Directory\n", path);
      osErrno = E_GENERAL;
      return -1;
    }

    //check if the read buffer is larger enough to hold the details
    if(directory_inode->size*sizeof(dirent_t) > size){
      dprintf("ERROR: type-%d inode-%d size-%d givensize-%d\n", directory_inode->type, parent_inode, directory_inode->size, size);
      osErrno = E_BUFFER_TOO_SMALL;
      return -1;
    }

    int sector, i;
    int increase_size = 0; // increase the buffer size by this amount
    char dirent_buffer[SECTOR_SIZE];

    
    for(sector = 0; sector < MAX_SECTORS_PER_FILE; sector++){ //iterate over each sector
      if(directory_inode->data[sector]){
        Disk_Read(directory_inode->data[sector], dirent_buffer);
        for(i = 0; i < DIRENTS_PER_SECTOR; i++){ // for each directory read it and copy it to the buffer
          dirent_t* dirent = (dirent_t*)(dirent_buffer+i*sizeof(dirent_t));
          if(dirent->inode){
            memcpy(buffer+increase_size, (void*)dirent, sizeof(dirent_t));
            increase_size += sizeof(dirent_t);
          }
        }
      }
    }

    dprintf("%d\n", directory_inode->size);
    return directory_inode->size;
  } else {
    dprintf("... directory '%s' is not found\n", path);
    return 0;
  }

}
