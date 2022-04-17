#include "common.h"
#define MEM_SIZE (0x8000000)
#define MEM_MASK (MEM_SIZE-1)
#define MEM_MASK_H (MEM_MASK&(-1))
#define MEM_MASK_W (MEM_MASK&(-3))
#define MEM_MASK_Q (MEM_MASK&(-7))

static uLL mem[MEM_SIZE>>3];

uLL mem_read(uLL addr){
    return mem[(addr-mem_start)>>3];
}

void mem_write(uLL addr,uLL data){
    RANGE(addr,mem_start,mem_end);
    mem[(addr-mem_start)>>3]=data;
}

void default_img(){
    printf("Nothing to load. Using the default img.\n");
    mem[0]=0x23b8020097020000LL;
    mem[1]=0x7300100003b50201LL;
    return;
}

void mem_init(char * filename){
    assert(mem_start+MEM_SIZE==mem_end);
    if(filename==NULL){
        default_img();
        return;
    }
    FILE * fp=fopen(filename,"rb");
    if(fp==NULL){
        default_img();
        return;
    }
    printf("Openfile %s\n",filename);
    fseek(fp,0,SEEK_END);
    long size=ftell(fp);
    printf("Imgfile is %s. size=%ld\n",filename,size);
    assert(size<=MEM_SIZE);
    fseek(fp,0,SEEK_SET);
    int ret=fread(mem,size,1,fp);
    assert(ret==1);
    fclose(fp);
    printf("Img initialization completed!\n");
}