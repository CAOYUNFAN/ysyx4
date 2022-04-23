#ifndef INCLUDE_COMMON

#include <cstdio>
#include <assert.h>
#include <stdlib.h>

#define ASNI_NONE       "\33[0m"
#define ASNI_FG_RED     "\33[1;31m"
#define ASNI_FG_BLUE    "\33[1;34m"
#define ASNI_FMT(str, fmt) fmt str ASNI_NONE

#define _Log(...) \
  do { \
    printf(__VA_ARGS__); \
  } while (0)

#define Log(format, ...) \
    _Log(ASNI_FMT("[%s:%d %s] " format, ASNI_FG_BLUE) "\n", \
        __FILE__, __LINE__, __func__, ## __VA_ARGS__)

#define Assert(cond, format, ...) \
    do { \
        if (!(cond)) { \
            fflush(stdout), fprintf(stderr, ASNI_FMT("[%s:%d %s]" format, ASNI_FG_RED) "\n", __FILE__,__LINE__,__func__,##  __VA_ARGS__); \
            assert(cond); \
        } \
    } while (0)

#define panic(format, ...) Assert(0, format, ## __VA_ARGS__)

#define RANGE(addr,start,end)\
    if((addr)<start||(addr)>end){\
        fprintf(stderr,"Unexpected Addr %p!\n",(void *)(addr));\
        assert((addr)>=start&&(addr)<=end);\
    }

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long long uLL;
using namespace std;
extern char * log_file;

#define INCLUDE_COMMON

#endif
