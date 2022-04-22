#include <regs.h>

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

#define Cao_show_reg(name,data) printf("%8s 0x%016lx %ld\n",name,data,data)

void reg_display() {
    for(int i=0;i<32;i++) Cao_show_reg(regs[i],mycpu->dbg_regs[i]);

    Cao_show_reg("pc",mycpu->pc); 
}