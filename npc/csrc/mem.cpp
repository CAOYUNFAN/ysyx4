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

void mem_init(char * filename){
    if(filename==NULL) return;
    FILE * fp=fopen(filename,"rb");
    if(fp==NULL){
        printf("Ops, nothing to load");
        return;
    }
    fseek(fp,0,SEEK_END);
    long size=ftell(fp);
    printf("Imgfile is %s. size=%ld",filename,size);
    assert(size<=MEM_SIZE);
    fseek(fp,0,SEEK_SET);
    int ret=fread(mem,size,1,fp);
    assert(ret==1);
    fclose(fp);
}