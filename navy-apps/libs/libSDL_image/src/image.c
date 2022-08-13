#define SDL_malloc  malloc
#define SDL_free    free
#define SDL_realloc realloc

#define SDL_STBIMAGE_IMPLEMENTATION
#include "SDL_stbimage.h"

SDL_Surface* IMG_Load_RW(SDL_RWops *src, int freesrc) {
  assert(src->type == RW_TYPE_MEM);
  assert(freesrc == 0);
  return NULL;
}

SDL_Surface* IMG_Load(const char *filename) {
  FILE *fd=fopen(filename,"r");
  fseek(fd,0,SEEK_END);
  int size=ftell(fd);
  unsigned char * buf=malloc(size);
  fseek(fd,0,SEEK_SET);
//  printf("File %s,IMG_SIZE:%d\n",filename,size);
  assert(fread(buf,1,size,fd)==size);
//  for(int i=0;i<size;++i) putchar(buf[i]);putchar('\n');
  SDL_Surface * ans=STBIMG_LoadFromMemory(buf,size);
//  printf("About to Complete!\n");
  assert(ans!=NULL);
  fclose(fd);
  free(buf);
//  printf("Complete!\n");
  return ans;
}

int IMG_isPNG(SDL_RWops *src) {
  return 0;
}

SDL_Surface* IMG_LoadJPG_RW(SDL_RWops *src) {
  return IMG_Load_RW(src, 0);
}

char *IMG_GetError() {
  return "Navy does not support IMG_GetError()";
}
