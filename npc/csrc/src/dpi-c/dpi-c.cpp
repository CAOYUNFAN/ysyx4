#include <common.h>
#include <debug.h>
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

extern "C" void data_read(uLL raddr,uLL *rdata){
    for(int i=0;i<3;i++) 
    if(raddr>=device_table[i].start&&raddr<device_table[i].end){
        Assert(device_table[i].input,"Regs %s is unreadable! 0x%llx cannot be read.",device_table[i].name,raddr);
        *rdata=device_table[i].input(raddr);
        #ifdef MTRACE
        Log("Read from memory %llx : 0x%llx == %lld",raddr,*rdata,*rdata);
        #endif
        return;
    }
    panic("Unexpected addr %llx",raddr);
}

extern "C" void data_write(uLL waddr, uLL wdata, u8 wmask) {
    #ifdef MTRACE
    Log("Write to memory %llx:0x%llx=%lld,wmask=%x",waddr,wdata,wdata,wmask);
    #endif
    for(int i=0;i<3;i++) 
    if(waddr>=device_table[i].start&&waddr<device_table[i].end){
        Assert(device_table[i].output,"Regs %s is unreadable! 0x%llx cannot be read.",device_table[i].name,waddr);
        device_table[i].output(waddr,wdata,wmask);
        return;
    }
    panic("Unexpected addr %llx",waddr);
}