#include <common.h>
#include <debug.h>

int exit_code=0;
int main(int argc,char * argv[]) {
  Log("Hello, ysyx!");
  extern void initialize(int argc,char * argv[]);
  initialize(argc,argv);
  extern void work();
  Log("Initialization completed!");
  work();
  Log("Simulation ended!");
  return exit_code;
}
