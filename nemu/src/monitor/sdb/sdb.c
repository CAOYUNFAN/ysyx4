#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args) {
  nemu_state.state=NEMU_QUIT;
  return -1;
}

static int cmd_help(char *args);
static int cmd_si(char *args);
static int cmd_info(char *args);
static int cmd_x(char *args);
static int cmd_p(char *args);
static int cmd_w(char *args);
static int cmd_d(char *args);
static int cmd_attach(char * args){difftest_attach();return 0;}
static int cmd_detach(char * args){difftest_detach();return 0;}
static int cmd_save(char * args);
static int cmd_load(char * args);

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
  {"x","Find the value of expression expr and take the result as the starting memeory address,which outputs n consecutive 4 bytes in hexadecimal form",cmd_x},
  {"p","Find the value of expression expr",cmd_p},
  {"w","When the value of expression expr changes, program execution is suspended",cmd_w},
  {"d","Delete the monitoring point with sequence number n",cmd_d},
  {"attach","start difftest mode (only when difftest is enabled)",cmd_attach},
  {"detach","stop difftest",cmd_detach},
  {"save","save img [pathname]",cmd_save},
  {"load","load img [pathname]",cmd_load}
  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

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
	if(*args=='r') isa_reg_display();
	if(*args=='w'){
		extern void show_checkpoints();
		show_checkpoints();
	}
	return 0;
}

static int cmd_x(char *args){
	int n;
	char ex[100];
	bool success=1;
	extern word_t vaddr_read(vaddr_t addr,int len);
	sscanf(args,"%d %s",&n,ex);
	word_t j=expr(ex,&success);
	if(!success){
		printf("Invalid expr!\n");
		return 0;
	}
	for(int i=0;i<n;++i,j+=4)
		printf("0x%08lx:\t0x%08lx\n",j,vaddr_read(j,4));
	return 0;
}

static int cmd_p(char *args){
	bool success;
	word_t ans=expr(args,&success);
	if(success) printf("%lu\t%lx\n",ans,ans);
	else printf("Mistakes happen.\n");
	return 0;
}

static int cmd_w(char *args){
	extern void new_WP(char *args);
	new_WP(args);
	return 0;
}

static int cmd_d(char *args){
	int x;sscanf(args,"%d",&x);
	extern void checkpoint_del(int x);
	checkpoint_del(x);
	return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
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
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

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

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}

#include <memory/paddr.h>
#define MAGIC_NAME(name) "ee" str(name)
const unsigned char magic1[]={0x11,0x45,0x14,'R','S','I','C','V','6','4'};
const char * magic2= MAP_ALLCSR(MAGIC_NAME) ;
const unsigned char magic3[]={0x19,0x19,0x81,0x00};
const unsigned char magic4[]={'C','P','U'};
const unsigned char magic5[]={'M','E','M','O','R','Y'};
#define MAGIC_LEN (sizeof(magic1)+strlen(magic2)+sizeof(magic3)+sizeof(magic4)+sizeof(magic5))

static int cmd_save(char * args){
  FILE * fd=fopen(args,"w");
  assert(fd);
  fwrite(magic1,1,sizeof(magic1),fd);
  fprintf(fd,"%s",magic2);
  fwrite(magic3,1,sizeof(magic3),fd);
  fwrite(magic4,1,sizeof(magic4),fd);
  fwrite(&cpu,sizeof(CPU_state),1,fd);
  fwrite(magic5,1,sizeof(magic5),fd);
  fwrite(guest_to_host(RESET_VECTOR),1,CONFIG_MSIZE,fd);
  fclose(fd);
  Log("Img save to %s",args);
  return 0;
}

static inline bool check_img(FILE * fd){
  fseek(fd,0,SEEK_END);
  Log("%ld %ld",ftell(fd),MAGIC_LEN+sizeof(CPU_state)+CONFIG_MSIZE);
  if(ftell(fd)!=MAGIC_LEN+sizeof(CPU_state)+CONFIG_MSIZE) return 0;
  fseek(fd,0,SEEK_SET);
  unsigned char * buf=malloc(MAGIC_LEN);
  
  #define check_file(id,offset)\
  fseek(fd,offset,SEEK_CUR);assert(fread(buf,1,sizeof(concat(magic,id)),fd)==sizeof(concat(magic,id)));\
  for(int i=0;i<sizeof(concat(magic,id));i++) if(buf[i]!=concat(magic,id)[i]) return 0;
  
  check_file(1,0);
  assert(fread(buf,1,strlen(magic2),fd)==strlen(magic2));
  for(int i=0;magic2[i];i++) if(buf[i]!=magic2[i]) return 0;
  check_file(3,0)
  check_file(4,0)
  check_file(5,sizeof(CPU_state))
  free(buf);
  return 1;
}

static int cmd_load(char * args){
  FILE * fd=fopen(args,"r");
  if(!fd){
    Log("file %s cannot be open!",args);
    return 0;
  }
  if(check_img(fd)){
    fseek(fd,sizeof(magic1)+strlen(magic2)+sizeof(magic3)+sizeof(magic4),SEEK_SET);
    assert(fread(&cpu,sizeof(CPU_state),1,fd)==1);
    fseek(fd,sizeof(magic5),SEEK_CUR);
    assert(fread(guest_to_host(RESET_VECTOR),1,CONFIG_MSIZE,fd)==CONFIG_MSIZE);
    Log("Load img from %s; difftest is turned off for restart.",args);
    cmd_detach(NULL);
  }else Log("file %s is not a suitable img!",args);
  fclose(fd);
  return 0;
}