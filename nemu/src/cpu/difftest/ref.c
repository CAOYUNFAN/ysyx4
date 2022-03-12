#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  printf("hello1!\n");
  assert(0);
}

void difftest_regcpy(void *dut, bool direction) {
  printf("hello2!\n");
  assert(0);
}

void difftest_exec(uint64_t n) {
  printf("hello3!\n");
  assert(0);
}

void difftest_raise_intr(word_t NO) {
  printf("hello4!\n");
  assert(0);
}

void difftest_init() {
  /* Perform ISA dependent initialization. */
  init_isa();
}
