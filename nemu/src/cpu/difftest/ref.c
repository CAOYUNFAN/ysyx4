#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if(direction==DIFFTEST_TO_DUT){
    memcpy(buf,guest_to_host(addr),n);
  }else{
    Assert(direction==DIFFTEST_TO_REF,"Unexpected direction %d",direction);
    memcpy(guest_to_host(addr),buf,n);
  }
  return;
}

void difftest_regcpy(void *dut, bool direction) {
  if(direction==DIFFTEST_TO_DUT){
    memcpy(dut,&cpu,sizeof(CPU_state));
  }else{
    Assert(direction==DIFFTEST_TO_REF,"Unexpected direction %d",direction);
    memcpy(&cpu,dut,sizeof(CPU_state));
  }
}

void difftest_exec(uint64_t n) {
  if(nemu_state.state==NEMU_END||nemu_state.state==NEMU_ABORT) panic("REF HAS ENDED!\n");
  cpu_exec(n);
}

void difftest_raise_intr(word_t NO) {
  cpu.pc=isa_raise_intr(NO,cpu.pc);
}

void difftest_init() {
  /* Perform ISA dependent initialization. */
  init_isa();
}
