#ifndef INCLUDE_MEMORY

#include <common.h>
#define mem_start    (0x80000000uLL)
#define mem_end      (0x88000000uLL)
#define MEM_SIZE (0x8000000)
uLL mem_read(uLL addr);
long mem_init(char * filename);
void mem_write(uLL addr,uLL data);
void * mem_addr();

#define INCLUDE_MEMORY
#endif
