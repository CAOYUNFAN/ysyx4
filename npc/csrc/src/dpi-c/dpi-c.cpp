#include <common.h>
#include <debug.h>
#include <memory.h>
#include <device.h>

extern "C" void assert_check_msg(bool cond,char * msg,...){
    if(!cond){
        va_list ap;
        va_start(ap,msg);
        vprintf(msg,ap);
        va_end(ap);
        assert(0);
    }
}

extern "C" void pmem_read(LL raddr,LL *rdata){
    
    *rdata=mem_read(raddr);
    #ifdef MTRACE
    if(mycpu->MemRd) Log("Read from memory %llx:0x%llx=%lld,realaddr=%lld,%lld",raddr&(-8uLL),*rdata,*rdata,((raddr-mem_start)&(MEM_SIZE-1))>>3,mem[39]);
    #endif
}
/*extern "C" void pmem_write(long long waddr, long long wdata, char wmask) {
    RANGE(waddr,mem_start,mem_end);
    #ifdef MTRACE
    Log("Write to memory %llx:0x%llx=%lld",addr&(-8uLL),data,data);
    #endif
    LL addr=(waddr-mem_start)>>3;
    for(int i=0,j=0;i<8;i++,j+=8)
    if(wmask&(1<<i)){
        uLL temp=(wdata&((1LL<<8)-1))<<j;
        wdata>>=8;
        mem[addr]=(mem[addr]&((1uLL<<j)-1))|temp|(mem[addr]&(-(1uLL<<(j+1))));
    }
}*/