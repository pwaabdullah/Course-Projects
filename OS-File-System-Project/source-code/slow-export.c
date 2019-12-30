#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "LibFS.h"

#define BFSZ 256

void usage(char *prog)
{
  printf("USAGE: %s [disk] file to_unix_file\n", prog);
  exit(1);
}

int main(int argc, char *argv[])
{
  char *diskfile, *path, *fname;
  if(argc != 3 && argc != 4) usage(argv[0]);
  if(argc == 4) { diskfile = argv[1]; path = argv[2]; fname = argv[3]; }
  else { diskfile = "default-disk"; path = argv[1]; fname = argv[2]; }

  if(FS_Boot(diskfile) < 0) {
    printf("ERROR: can't boot file system from file '%s'\n", diskfile);
    return -1;
  }
  
  int fd = File_Open(path);
  if(fd < 0) {
    printf("ERROR: can't open file '%s'\n", path);
    return -2;
  }

  FILE* fptr = fopen(fname, "w");
  if(!fptr) {
    printf("ERROR: can't open file '%s' to export\n", fname);
    return -3;
  }

  char buf[BFSZ]; int sz;
  do {
    sz = File_Read(fd, buf, BFSZ);
    if(sz < 0) {
      printf("ERROR: can't read file '%s'\n", path);
      return -4;
    } else if(sz > 0) {
      int wsz = fwrite(buf, 1, sz, fptr);
      if(wsz != sz) {
	printf("ERROR: can't write file '%s'\n", fname);
	return -5;
      }
    }
  } while(sz > 0);
  
  fclose(fptr);
  File_Close(fd);
  
  if(FS_Sync() < 0) {
    printf("ERROR: can't sync disk '%s'\n", diskfile);
    return -3;
  }
  return 0;
}
