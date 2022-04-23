#include <memory.h>
#include <regs.h>

static uLL mem[MEM_SIZE>>3];

uLL mem_read(uLL addr){
    return mem[((addr-mem_start)&(MEM_SIZE-1))>>3];
}

void mem_write(uLL addr,uLL data){
    RANGE(addr,mem_start,mem_end);
    mem[(addr-mem_start)>>3]=data;
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
    Log("Openfile %s",filename);
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
