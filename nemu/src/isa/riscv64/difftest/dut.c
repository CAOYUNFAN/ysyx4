#include <isa.h>
#include <cpu/difftest.h>
#include "../local-include/reg.h"

#define CHECK(name) \
if(cpu.name !=ref_r->name ){\
  Log("Difftest: different on " str(name) ",ref=%lx",ref_r->name);\
  return false;\
}

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  for(int i=0;i<32;++i) if(cpu.gpr[i]!=ref_r->gpr[i]) {
    Log("Difftest: different on reg[%d],ref=%lx",i,ref_r->gpr[i]);
    return false;
  }
  if(ref_r->pc!=pc) {
    Log("Difftest: different on pc,ref=%lx",ref_r->pc);
    return false;
  }
  
  CHECK(mepc)
  CHECK(mstatus)
  CHECK(mcause)
  CHECK(mtvec)
  
  return true;
}

void isa_difftest_attach() {
}
