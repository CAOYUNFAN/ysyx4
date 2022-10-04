#include <common.h>
#include <debug.h>
#include <device.h>
#include "verilated_dpi.h"

uint64_t *cpu_gpr = NULL, *pc =NULL,*pc_m=NULL;
extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void set_pc_ptr(const svOpenArrayHandle r){
    pc=(uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void set_pc_m_ptr(const svOpenArrayHandle r){
    pc_m=(uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void data_read(uLL raddr,uLL *rdata,u8 * error){
    for(int i=0;i<6;i++) if(device_table[i]->in_range(raddr)){
        device_table[i]->input(raddr,rdata,error);
        #ifdef MTRACE
        Log("read from addr %llx: %llx",raddr,*rdata);
        #endif
        return;
    }
    *rdata=0x1145141919810uLL;
    *error=1;
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