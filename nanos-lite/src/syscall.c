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

size_t sys_write(int fd,void * buf,size_t count){
  int i=0;
  if(fd==1||fd==2) for(char * ch=buf;i<count;i++,ch++) putch(*ch);
  else panic("TODO");
  return count; 
}

Context * do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;

  switch (a[0]) {
    case SYS_yield: c=do_yield(c); break;
    case SYS_exit: c=do_exit(c); break;
    case SYS_write: c->GPRx=sys_write((int)c->GPR2,(void *)c->GPR3,c->GPR4); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
  return c;
}
