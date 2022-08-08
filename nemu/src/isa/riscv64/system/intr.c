#include <isa.h>

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  /* TODO: Trigger an interrupt/exception with ``NO''.
   * Then return the address of the interrupt/exception vector.
   */
  cpu.mepc=epc;
  cpu.mcause=NO;
  cpu.mstatus=(cpu.mstatus&(~(word_t)((1<<3)|(1<<7))))|(((cpu.mstatus>>3)&1)<<7);
  return cpu.mtvec;
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
