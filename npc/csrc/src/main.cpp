#include <common.h>
#include <debug.h>

int main(int argc,char * argv[]) {
  Log("Hello, ysyx!");
  extern void initialize(int argc,char * argv[]);
  initialize(argc,argv);
  Log("Initialization completed!");
  extern void work();
  extern void device_init();
  device_init();
  work();
  Log("Exit normally!");
  return 0;
}
