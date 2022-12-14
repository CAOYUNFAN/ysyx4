#include <common.h>
#include <debug.h>
#include <kernel.h>
#include <memory.h>
#include <getopt.h>

int is_batch=0,is_difftest=0;
void sdb_set_batch_mode(){
  is_batch=1;
  return;
}

char * img_file=NULL, * diff_so_file=NULL;
FILE * Log_file =NULL;
void init_log(char * log_file){
  Log_file=fopen(log_file,"w");
  if(!Log_file) Log("Cannot open/create file %s as log. No log file.",log_file);
  else Log("Log file is %s",log_file);
}

static int size;
emu * mycpu=NULL;
int difftest_port=0;
void init_difftest(char * ref_so_file, unsigned long img_size);
void parse_args(int argc,char * argv[]){
  static const option table[] ={
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'l': init_log(optarg); break;
      case 'd': is_difftest=1;diff_so_file = optarg;; break;
      case 1: size=mem_init(optarg);return;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\n");
        exit(0);
    }
  }
  size=mem_init(NULL);
  return;
}

void cpu_init(){
  mycpu->reset=1;
  mycpu->clock=0;
  mycpu->eval();
  mycpu->clock=1;
  mycpu->eval();
  mycpu->clock=0;
  mycpu->eval();
  mycpu->reset=0;
}

void initialize(int argc,char * argv[]){
  mycpu = new emu;
  parse_args(argc,argv);
  extern void device_init();
  device_init();
  cpu_init();
  if(is_difftest) init_difftest(diff_so_file,size);
}
