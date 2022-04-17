#include "emu.h"
#include "common.h"
#include <getopt.h>
using namespace std;

emu * mycpu=NULL;

int is_batch=0;

void sdb_set_batch_mode(){
  is_batch=1;
  return;
}

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
    RANGE(mycpu->pc,mem_start,mem_end);
    mycpu->instr_data=mem_read(mycpu->pc);
    mycpu->data_Rd_data=mem_read(mycpu->addr);
    mycpu->clk=1;
    mycpu->eval();
    if(mycpu->MemWr&&!mycpu->error) mem_write(mycpu->addr,mycpu->data_Wr_data);
    mycpu->clk=0;
    mycpu->eval();
  }
}

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

char * img_file=NULL;
void parse_args(int argc,char * argv[]){
  static const option table[] ={
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"elf"      , required_argument, NULL, 'e'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': //sscanf(optarg, "%d", &difftest_port); break;
      case 'l': //log_file = optarg; break;
      case 'd': //diff_so_file = optarg; break;
      case 'e': /*
        #ifdef CONFIG_FTRACE
        elf_file=optarg;
        #else
        Log("System do not support function trace unless it is enabled."); 
        #endif
        break;*/
      case 1: mem_init(optarg);return;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\t-e,--elf=elf            read function symbols from elf (only when enable ftrace)\n");
        printf("\n");
        exit(0);
    }
  }
  mem_init(NULL);
  return;
}

int main(int argc,char * argv[]) {
  printf("Hello, ysyx!\n");
  mycpu = new emu;
  parse_args(argc,argv);
  cpu_init();
  printf("Initialization completed!\n");
  if(is_batch) cpu_exec(-1uLL);
  else{
    char ch=getchar();
    if(ch=='c') cpu_exec(-1uLL);
    if(ch=='s') cpu_exec(1);
    if(ch=='r'){
      for(int i=0;i<32;++i) printf("%5s: 0x%064lx %ld\n",regs[i],mycpu->dbg_regs[i],mycpu->dbg_regs[i]);
      printf("%5s: %lx\n","pc",mycpu->pc);
    }
  }
  if(!mycpu->error){
    if(!mycpu->status) printf("SUCCESS!\n");
    else printf("FAIL!\n");
  }else printf("unkown command on pc=%lx\n",mycpu->pc);
  return 0;
}
