#include <isa.h>
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  for(int i=0;i<32;++i) if(cpu.gpr[i]!=ref_r->gpr[i]) {
    Log("Difftest: different on reg[%d]",i);
    return false;
  }
  if(cpu.pc!=pc) {
    Log("Difftest: different on pc");
    return false;
  }
  return true;
}

void isa_difftest_attach() {
}
