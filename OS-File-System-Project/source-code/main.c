#include <stdio.h>
#include <stdlib.h>
#include "LibFS.h"

void usage(char *prog)
{
  fprintf(stderr, "USAGE: %s <disk_image_file>\n", prog);
  exit(1);
}

int main(int argc, char *argv[])
{
  if (argc != 2) usage(argv[0]);

  if(FS_Boot(argv[1]) < 0) {
    fprintf(stderr, "ERROR: can't boot file system from file %s\n", argv[1]);
    return -1;
  }
 
  if(FS_Sync() < 0) {
    fprintf(stderr, "ERROR: can't sync file system with file %s\n", argv[1]);
    return -1;
  }
    
  return 0;
}
