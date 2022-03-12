#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "emu.h"
typedef unsigned long long uLL;
typedef unsigned int uint;

uint imem_read(uLL pc);
int main() {
  printf("Hello, ysyx!\n");
  std::shared_ptr<emu> mycpu = std::make_shared<emu>();
  for(int i=0;i<10;++i) {
    mycpu->instr=imem_read(mycpu->pc);
    mycpu->eval();
    mycpu->clk = 0;
    mycpu->eval();
    mycpu->clk = 1;
    mycpu->eval();
  }
  return 0;
}
