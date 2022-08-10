#include <common.h>
#include <debug.h>
#include <kernel.h>
#include <debug.h>

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

extern FILE * Log_file;

#define Cao_show_reg(name,data) \
  do{\
    printf("%8s 0x%016lx %ld\n",name,data,data);\
    if(Log_file){\
      fprintf(Log_file,"%8s 0x%016lx %ld\n",name,data,data);\
    }\
  }while(0)
  
void reg_display() {
    for(int i=0;i<32;i++) Cao_show_reg(regs[i],mycpu->dbg_regs[i]);
    Cao_show_reg("pc",mycpu->pc); 
}

bool difftest_checkregs(CPU_state * ref,uLL pc){

  for(int i=0;i<32;i++) if(mycpu->dbg_regs[i]!=ref->gpr[i]) {
    Log("DIFFERENT on %s, ref=%llx",regs[i],ref->gpr[i]);
    return false;
  }
  if(pc!=ref->pc) {
    Log("DIFFERENT on pc, ref=%llx",ref->pc);
    return false;
  }
  #define CHECK(name) \
  if(mycpu-> name !=ref-> name ){\
    Log("DIFFERENT on " str(name) ", ref=%llx",ref-> name);\
    return false;\
  }

  CSR_MAP(CHECK)

  return true;
}

CPU_state * current_cpu(){
  static CPU_state cpu;
  for(int i=0;i<32;i++) cpu.gpr[i]=mycpu->dbg_regs[i];
  cpu.pc=mycpu->pc;

  #define SET_REGS(name) cpu. name = mycpu -> name ;
  CSR_MAP(SET_REGS)

  return &cpu;
}