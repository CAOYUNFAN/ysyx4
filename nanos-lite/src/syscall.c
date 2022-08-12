#include <common.h>
#include <fs.h>
#include "syscall.h"

Context * do_yield(Context * c){
  Log("YIELD!");
  return c;
}

Context * do_exit(Context * c){
  halt(c->GPR2);
  return c;
}

int sys_brk(void * addr){
  return 0;
}

struct timeval{
  long tv_sec,tv_usec;
};
struct timezone{
  int tz_minuteswest;		/* Minutes west of GMT.  */
  int tz_dsttime;		/* Nonzero if DST is ever in effect.  */
};

uintptr_t sys_gettimeofday(struct timeval *tv,struct timezone * tz){
  uint64_t time=io_read(AM_TIMER_UPTIME).us;
  if(tv){
    tv->tv_sec=time/1000000;
    tv->tv_usec=time;
  }
  if(tz) tz->tz_dsttime=tz->tz_minuteswest=0;
  return 0;
}

Context * do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;a[1]=c->GPR2;a[2]=c->GPR3;a[3]=c->GPR4;

  switch (a[0]) {
    case SYS_yield: c=do_yield(c); break;
    case SYS_exit: c=do_exit(c); break;
    case SYS_brk: c->GPRx=sys_brk((void *)a[1]);break;
    case SYS_read: c->GPRx=fs_read(a[1],(void *)a[2],a[3]); break;
    case SYS_write: c->GPRx=fs_write((int)a[1],(void *)a[2],a[3]); break;
    case SYS_open: c->GPRx=fs_open((char *)a[1],a[2],a[3]); break;
    case SYS_lseek: c->GPRx=fs_lseek(a[1],a[2],a[3]); break;
    case SYS_close: c->GPRx=fs_close(a[1]); break;
    case SYS_gettimeofday: c->GPRx=sys_gettimeofday((struct timeval *)a[1],(struct timezone *)a[2]);break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
  return c;
}
