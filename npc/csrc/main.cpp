#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "emu.h"
#include "common.h"
using namespace std;

uint imem_read(uLL pc);
int main() {
  printf("Hello, ysyx!\n");
  shared_ptr<emu> mycpu = make_shared<emu>();
  for(int i=1;i<=10;++i){
    mycpu->instr=mem_read(mycpu->pc);
    mycpu->eval();
    mycpu->clk = 0;
    mycpu->eval();
    mycpu->clk = 1;
    mycpu->eval();
  }
  return 0;
}
