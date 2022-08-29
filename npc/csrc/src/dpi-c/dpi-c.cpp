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

extern "C" void data_read(uLL raddr,uLL *rdata,u8 * valid){
    for(int i=0;i<6;i++) if(device_table[i]->in_range(raddr)){
        *rdata=device_table[i]->input(raddr);
        *valid=0;
        #ifdef MTRACE
        Log("read from addr %llx: %llx",raddr,*rdata);
        #endif
        return;
    }
    *rdata=0x1145141919810uLL;
    *valid=1;
    #ifdef MTRACE
    Log("fail read addr=%llx",raddr);
    #endif
//    panic("Unexpected addr %llx",raddr);
}

extern "C" void data_write(uLL waddr, uLL wdata, u8 wmask) {
    #ifdef MTRACE
    Log("Write to memory %llx:0x%llx=%lld,wmask=%x",waddr,wdata,wdata,wmask);
    #endif
    for(int i=0;i<6;i++) if(device_table[i]->in_range(waddr)){
        device_table[i]->output(waddr,wdata,wmask);
        return;
    }
    panic("Unexpected addr %llx",waddr);
}