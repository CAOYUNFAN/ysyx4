#include <common.h>
#include <debug.h>
#include <memory.h>
#include <kernel.h>

static uLL mem[MEM_SIZE>>3];

uLL pmem_read(uLL addr){
    return mem[(addr-mem_start)>>3];
}

void pmem_write(uLL addr,uLL data,u8 mask){
    RANGE(addr,mem_start,mem_end);
    uLL &pos=mem[(addr-mem_start)>>3];
    for(u64 now=0xff;mask;mask>>=1,now<<=8) if(mask&1){
        pos=(pos&~mask)|(data&0xff);
        data>>=8;
    }
}

void default_img(){
    Log("Nothing to load. Using the default img.");
    mem[0]=0x0002b82300000297LL;
    mem[1]=0x001000730102b503LL;
    return;
}

long mem_init(char * filename){
    assert(mem_start+MEM_SIZE==mem_end);
    if(filename==NULL){
        default_img();
        return 16;
    }
    FILE * fp=fopen(filename,"rb");
    if(fp==NULL){
        default_img(); 
        return 16;
    }
    fseek(fp,0,SEEK_END);
    long size=ftell(fp);
    Log("Imgfile is %s. size=%ld",filename,size);
    assert(size<=MEM_SIZE);
    fseek(fp,0,SEEK_SET);
    int ret=fread(mem,size,1,fp);
    assert(ret==1);
    fclose(fp);
    Log("Img initialization completed!");
    return size;
}

void * mem_addr(){
    return (void *)mem;
}
