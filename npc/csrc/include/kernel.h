#include "emu.h"
#include "allcsr.h"
extern emu * mycpu;
extern int is_batch;

#define def(name) \
  uLL name ;

typedef struct {
  uLL gpr[32];
  uLL pc;

  CSR_MAP(def)
  
} CPU_state;
void reg_display();
bool difftest_checkregs(CPU_state * ref,uLL pc);
CPU_state * current_cpu();
