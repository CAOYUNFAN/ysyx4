#include "emu.h"
extern emu * mycpu;
extern int is_batch;

typedef struct {
  uLL gpr[32];
  uLL pc;
  uLL mepc,mstatus,mcasue,mtvec;
} CPU_state;
void reg_display();
bool difftest_checkregs(CPU_state * ref,uLL pc);
