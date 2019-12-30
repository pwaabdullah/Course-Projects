#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "LibFS.h"

void usage(char *prog)
{
  printf("USAGE: %s [disk] file\n", prog);
  exit(1);
}

int main(int argc, char *argv[])
{
  char *diskfile, *path;
  if(argc != 2 && argc != 3) usage(argv[0]);
  if(argc == 3) { diskfile = argv[1]; path = argv[2]; }
  else { diskfile = "default-disk"; path = argv[1]; }

  if(FS_Boot(diskfile) < 0) {
    printf("ERROR: can't boot file system from file '%s'\n", diskfile);
    return -1;
  }
  
  if(File_Create(path) < 0) {
    printf("ERROR: can't create file '%s'\n", path);
    return -2;
  }
  printf("file '%s' created successfully\n", path);

  if(FS_Sync() < 0) {
    printf("ERROR: can't sync disk '%s'\n", diskfile);
    return -3;
  }
  return 0;
}
