#include "common.h"
#define MEM_SIZE (8192)
#define MEM_MASK (MEM_SIZE-1)
#define MEM_MASK_H (MEM_MASK&(-1))
#define MEM_MASK_W (MEM_MASK&(-3))
#define MEM_MASK_Q (MEM_MASK&(-7))

static uchar mem[MEM_SIZE];
uLL mem_read(uLL addr,int len){
    switch (len){
        case 1:return (uLL)mem[addr&MEM_MASK];
        case 2:return (uLL)(*(ushort *)(mem+(addr&MEM_MASK_H)));
        case 4:return (uLL)(*(uint *)(mem+(addr&MEM_MASK_W)));
        case 8:return (uLL)(*(uLL *)(mem+(addr&MEM_MASK_Q)));
        default: panic("Unexpected len!");
    }
}