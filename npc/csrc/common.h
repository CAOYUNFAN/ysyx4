#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#define panic(message)\
    printf("%s",message);\
    assert(0);

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long long uLL;

uLL mem_read(uLL addr,int len);