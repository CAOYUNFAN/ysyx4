#include <common.h>
#include <debug.h>

int exit_code=0;
int main(int argc,char * argv[]) {
  Log("Hello, ysyx!");
  extern void initialize(int argc,char * argv[]);
  initialize(argc,argv);
  Log("Initialization completed!");
  extern void work();
  extern void device_init();
  device_init();
  work();
  Log("Simulation ended!");
  return exit_code;
}
