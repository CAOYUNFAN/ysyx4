#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#define panic(message)\
    fprintf(stderr,"%s",message);\
    assert(0);

#define RANGE(addr,start,end)\
    if((addr)<start||(addr)>end){\
        fprintf(stderr,"Unexpected Addr %p!\n",(void *)(addr));\
        assert((addr)>=start&&(addr)<=end);\
    }
#define mem_start    (0x80000000uLL)
#define mem_end      (0x88000000uLL)

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long long uLL;

uLL mem_read(uLL addr);
void mem_init(char * filename);
void mem_write(uLL addr,uLL data);
