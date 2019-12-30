#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "LibFS.h"

void usage(char *prog)
{
  printf("USAGE: %s <disk_image_file>\n", prog);
  exit(1);
}

int main(int argc, char *argv[])
{
  if (argc != 2) usage(argv[0]);

  if(FS_Boot(argv[1]) < 0) {
    printf("ERROR: can't boot file system from file '%s'\n", argv[1]);
    return -1;
  } else printf("file system booted from file '%s'\n", argv[1]);

  char* fn;

  fn = "/first-file";
  if(File_Create(fn) < 0) printf("ERROR: can't create file '%s'\n", fn);
  else printf("file '%s' created successfully\n", fn);

  fn = "/second-file";
  if(File_Create(fn) < 0) printf("ERROR: can't create file '%s'\n", fn);
  else printf("file '%s' created successfully\n", fn);

  fn = "/first-dir";
  if(Dir_Create(fn) < 0) printf("ERROR: can't create dir '%s'\n", fn);
  else printf("dir '%s' created successfully\n", fn);
  
  fn = "/first-dir/second-dir";
  if(Dir_Create(fn) < 0) printf("ERROR: can't create dir '%s'\n", fn);
  else printf("dir '%s' created successfully\n", fn);
  
  fn = "/first-file/second-dir";
  if(Dir_Create(fn) < 0) printf("ERROR: can't create dir '%s'\n", fn);
  else printf("dir '%s' created successfully\n", fn);

  fn = "/first_dir/third*dir";
  if(Dir_Create(fn) < 0) printf("ERROR: can't create dir '%s'\n", fn);
  else printf("dir '%s' created successfully\n", fn);
  
  fn = "/first-file";
  if(File_Unlink(fn) < 0) printf("ERROR: can't unlink file '%s'\n", fn);
  else printf("file '%s' unlinked successfully\n", fn);

  fn = "/first-dir";
  if(Dir_Unlink(fn) < 0) printf("ERROR: can't unlink dir '%s'\n", fn);
  else printf("dir '%s' unlinked successfully\n", fn);

  fn = "/first-dir/second-dir";
  if(Dir_Unlink(fn) < 0) printf("ERROR: can't unlink dir '%s'\n", fn);
  else printf("dir '%s' unlinked successfully\n", fn);

  fn = "/second-file";
  int fd = File_Open(fn);
  if(fd < 0) printf("ERROR: can't open file '%s'\n", fn);
  else printf("file '%s' opened successfully, fd=%d\n", fn, fd);

  char buf[1024]; char* ptr = buf;
  for(int i=0; i<1000; i++) {
    sprintf(ptr, "%d %s", i, (i+1)%10==0 ? "\n" : "");
    ptr += strlen(ptr);
    if(ptr >= buf+1000) break;
  }
  if(File_Write(fd, buf, 1024) != 1024)
    printf("ERROR: can't write 1024 bytes to fd=%d\n", fd);
  else printf("successfully wrote 1024 bytes to fd=%d\n", fd);
  
  if(File_Close(fd) < 0) printf("ERROR: can't close fd %d\n", fd);
  else printf("fd %d closed successfully\n", fd);
  
  if(FS_Sync() < 0) {
    printf("ERROR: can't sync file system to file '%s'\n", argv[1]);
    return -1;
  } else printf("file system sync'd to file '%s'\n", argv[1]);
    
  return 0;
}
