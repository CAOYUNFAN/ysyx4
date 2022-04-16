#include "emu.h"
#include "common.h"
using namespace std;

emu * mycpu=NULL;

void cpu_init(){
  mycpu->rst=1;
  mycpu->clk=0;
  mycpu->eval();
  mycpu->clk=1;
  mycpu->eval();
  mycpu->clk=0;
  mycpu->eval();
  mycpu->rst=0;
}

void cpu_exec(uLL n){
  while (n--){
    if(mycpu->error||mycpu->done) return;
    mycpu->instr_data=mem_read(mycpu->pc);
    mycpu->data_Rd_data=mem_read(mycpu->addr);
    mycpu->clk=1;
    mycpu->eval();
    if(mycpu->MemWr&&!mycpu->error) mem_write(mycpu->addr,mycpu->data_Wr_data);
    mycpu->clk=0;
    mycpu->eval();
  }
}

int main(int argc,char ** argv) {
  printf("Hello, ysyx!\n");
  assert(argc<=2);
  mem_init(argv[1]);
  mycpu = (emu *)malloc(sizeof(emu));
  cpu_init();
  cpu_exec(-1uLL);
  return 0;
}
