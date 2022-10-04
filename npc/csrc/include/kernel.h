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

struct status_of_cpu{
  bool valid : 1;
  bool done  : 1;
  bool error : 1;
  unsigned long long reserved : 61;
};
extern status_of_cpu cpu_status;

void reg_display();
bool difftest_checkregs(CPU_state * ref,uLL pc);
CPU_state * current_cpu();
void disable_difftest();
void enable_difftest();