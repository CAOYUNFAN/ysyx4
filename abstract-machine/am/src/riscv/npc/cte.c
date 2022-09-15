#include <am.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  volatile unsigned long long * ptr=(unsigned long long *)(0x2004000);
  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      case 11: c->mepc+=4; ev.event = (c->gpr[17]==-1?EVENT_YIELD:EVENT_SYSCALL); break;
      case (1uLL<<63uLL)+7uLL: ev.event =EVENT_IRQ_TIMER; *ptr+=10000;break;
      default: ev.event = EVENT_ERROR; break;
    }
    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  return NULL;
}

void yield() {
  asm volatile("li a7, -1; ecall");
}

bool ienabled() {
  unsigned long x,y;
  asm("csrr %0,mstatus; csrr %1,mie":"=r"(x),"=r"(y):);
  return (x>>3&1)&&(y>>7&1);
}

void iset(bool enable) {
  asm("csrw mie,%0": :"r"(enable?0x80uLL:0));
  asm("csrw mstatus,%0" : :"r"(enable?0x00000000a0001888uLL:0x00000000a0001880uLL));
}
