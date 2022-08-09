#include <common.h>
#include "syscall.h"

Context * do_yield(Context * c){
  Log("YIELD!");
  return c;
}

Context * do_exit(Context * c){
  halt(0);
  return c;
}

Context * do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;

  switch (a[0]) {
    case SYS_yield: c=do_yield(c); break;
    case SYS_exit: c=do_exit(c); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
  return c;
}
