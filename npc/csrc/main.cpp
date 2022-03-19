#include "emu.h"
#include "common.h"
using namespace std;

uint imem_read(uLL pc);
int main(int argc,char ** argv) {
  printf("Hello, ysyx!\n");
  assert(argc<=1);
  printf("%d\n",argc);
  mem_init(*argv);
  shared_ptr<emu> mycpu = make_shared<emu>();
  for(int i=1;i<=10;++i){
    mycpu->instr=mem_read(mycpu->pc,4);
    mycpu->eval();
    mycpu->clk = 0;
    mycpu->eval();
    mycpu->clk = 1;
    mycpu->eval();
  }
  return 0;
}
