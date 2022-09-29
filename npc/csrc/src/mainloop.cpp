#include <common.h>
#include <debug.h>
#include <memory.h>
#include <kernel.h>
uLL oldpc;
int global_status;
void trace_and_difftest(){
    extern int is_difftest;
    if(is_difftest){
        extern void difftest_step(uLL,uLL);
        difftest_step(oldpc,mycpu->pc_nxt);
    }
}

#ifdef INSTR
#define CC(...) Log(__VA_ARGS__)
#else
#define CC(...) (0)
#endif 

void data_read(uLL addr,unsigned long * data,u8 * error);
void data_write(uLL addr,unsigned long *data,u8 mask, u8 * error);

struct read_stuct{
  uint32_t left,addr,id;
}read_table[2];

struct{
  uint32_t left,addr;
  u8 tag,error;
}write_table;

static inline void add_ar(){
  mycpu->io_master_arready=1;
  int pos=0;
  if(read_table[0].left) pos=1;
  read_table[pos].id=mycpu->io_master_arid;
  read_table[pos].addr=mycpu->io_master_araddr;
  read_table[pos].left=mycpu->io_master_arlen+1;
  return;
}

static inline void add_aw(){
  mycpu->io_master_awready=1;
  write_table.left=mycpu->io_master_awlen+1;
  write_table.addr=mycpu->io_master_awaddr;
  Log("new write:%x,%d",write_table.addr,write_table.left);
  write_table.error=0;
}

static inline void deal_r(){
  int pos=0;if(!read_table[0].left) pos=1;
  if(!read_table[pos].left){
    mycpu->io_master_rvalid=0;
    return;
  }
  mycpu->io_master_rvalid=1;
  mycpu->io_master_rid=read_table[pos].id;
  mycpu->io_master_rlast=(read_table[pos].left==1);
  u8 error;
  data_read(read_table[pos].addr,&mycpu->io_master_rdata,&error);
  mycpu->io_master_rresp=error?3:0;
  read_table[pos].left--;
  read_table[pos].addr+=64/8;
}

static inline void deal_w(){
  if(!write_table.left){
    Assert(!mycpu->io_master_wvalid,"should not write!");
    mycpu->io_master_wready=0;
    return;
  }
  Assert(mycpu->io_master_wvalid,"should write!");
  mycpu->io_master_wready=1;
  u8 error;
  data_write(write_table.addr,&mycpu->io_master_wdata,mycpu->io_master_wstrb,&error);
  write_table.addr+=64/8;
  write_table.left--;
  if(!write_table.left) Assert(mycpu->io_master_wlast,"Write expect to be ended!");
  else Assert(!mycpu->io_master_wlast,"Write expect not to be ended!");
  write_table.error|=error;
  write_table.tag=(!write_table.left);
}

static inline void deal_b(){
  if(!write_table.tag){
    mycpu->io_master_bvalid=0;
    return;
  }
  mycpu->io_master_bvalid=1;
  write_table.tag=0;
  mycpu->io_master_bresp=write_table.error?3:0;
  mycpu->io_master_bid=0;
}

inline void cpu_exec_once(){
    mycpu->clock=1;
    CC("One cycle-UP!");
    mycpu->eval();
    deal_b();
    deal_r();
    deal_w();
    if(mycpu->io_master_arvalid) add_ar();
    else mycpu->io_master_arready=0;
    if(mycpu->io_master_awvalid) add_aw();
    else mycpu->io_master_awready=0;
    mycpu->clock=0;
    CC("One cycle-DOWN!");
    mycpu->eval();
    CC("One cycle-Completed!");
}

extern int exit_code;
void statistics(){
  if(mycpu->error) {
    Log("Error has happened. NPC aborted.");
    reg_display();
    exit_code=1;
  }
  else{
    if(mycpu->dbg_regs[10]) Log("Npc hit bad trap.");
    else Log("Npc hit good trap.");
    exit_code=mycpu->dbg_regs[10];
  }
}

void cpu_exec(uLL n){
    if(mycpu->valid&&(mycpu->error||mycpu->done)){
      Log("Simulation has ended. Please restart the system mannually");
      return;
    }
    global_status=1;
    while (n--){
        oldpc=mycpu->pc_nxt;
        int tt=0;
        cpu_exec_once();
        while(!mycpu->valid&&tt<200) cpu_exec_once(),++tt;
        if(!mycpu->valid){
          Log("npc run too much cycles!");
          reg_display();
          exit(1);
        }
        if(mycpu->valid&&(mycpu->error||mycpu->done)) {
          statistics();
          return;
        }
        if(mycpu->valid) trace_and_difftest();
        extern void device_update();
        device_update();
    }
    global_status=0;
}
char line_read[1000];
static char* rl_gets() {
    printf("(npc) ");
    int x=0;
    line_read[0]=getchar();
    while (line_read[x]!='\n') line_read[++x]=getchar();
    line_read[x]=0;  
    return line_read;
}

static int cmd_c(char *args) {cpu_exec(-1uLL);return 0;}
static int cmd_q(char *args) {exit(0);}
static int cmd_help(char *args);
static int cmd_si(char *args);
static int cmd_info(char *args);
static int cmd_attach(char * args){enable_difftest();return 0;}
static int cmd_detach(char * args){disable_difftest();return 0;}

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display informations about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },

  {"si","Let the program execute N instructions in a single step and pause execution, when N is not given, it defaults to 1",cmd_si},
  {"info"," r :print register status; w :print monitoring point information",cmd_info},
  {"attach","enable dittest",cmd_attach},
  {"detach","disable dittest",cmd_attach}
  /* TODO: Add more commands */

};

#define NR_CMD (sizeof(cmd_table)/sizeof(cmd_table[0]))

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

static int cmd_si(char *args){
	char *temp=strtok(args," ");
	int x=(temp==NULL)?1:atol(temp);
	cpu_exec(x);
	return 0;
}

static int cmd_info(char *args){
    reg_display();
	  return 0;
}

void work(){
    if(is_batch) {
        cpu_exec(-1uLL);
        return;
    }

    for (char *str; (str = rl_gets()) != NULL; ) {
        char *str_end = str + strlen(str);

        /* extract the first token as the command */
        char *cmd = strtok(str, " ");
        if (cmd == NULL) { continue; }

        /* treat the remaining string as the arguments,
        * which may need further parsing
        */
        char *args = cmd + strlen(cmd) + 1;
        if (args >= str_end)  args =NULL;

        int i;
        for (i = 0; i < NR_CMD; i ++) {
        if (strcmp(cmd, cmd_table[i].name) == 0) {
            if (cmd_table[i].handler(args) < 0) { return; }
            break;
        }
        }

        if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
    }
}