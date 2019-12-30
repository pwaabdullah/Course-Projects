#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "LibFS.h"

void usage(char *prog)
{
  printf("USAGE: %s [disk] dir\n", prog);
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
  int sz = Dir_Size(path);
  if(sz < 0) {
    printf("ERROR: can't list '%s'\n", path);
    return -2;
  } else if (sz == 0) {
    printf("directory '%s': empty\n", path);
    return 0;
  }
  
  char* buf = malloc(sz);
  int entries = Dir_Read(path, buf, sz);
  if(entries < 0) {
    printf("ERROR: can't list '%s'\n", path);
    return -3;
  }
  
  printf("directory '%s':\n     %-15s\t%-s\n", path, "NAME", "INODE");
  int idx = 0;
  for(int i=0; i<entries; i++) {
    printf("%-4d %-15s\t%-d\n", i, &buf[idx], *(int*)&buf[idx+16]);
    idx += 20;
  }
  free(buf);

  if(FS_Sync() < 0) {
    printf("ERROR: can't sync disk '%s'\n", diskfile);
    return -3;
  }
  return 0;
}
