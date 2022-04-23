#ifndef INCLUDE_REGS

#include <common.h>
#include <kernel.h>
typedef struct {
  uLL gpr[32];
  uLL pc;
} CPU_state;
void reg_display();
bool difftest_checkregs(CPU_state * ref,uLL pc);

#define INCLUDE_REGS
#endif
