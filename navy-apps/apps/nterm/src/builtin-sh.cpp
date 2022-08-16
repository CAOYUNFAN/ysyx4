#include <nterm.h>
#include <stdarg.h>
#include <unistd.h>
#include <SDL.h>
#include <string.h>

char handle_key(SDL_Event *ev);

static void sh_printf(const char *format, ...) {
  static char buf[256] = {};
  va_list ap;
  va_start(ap, format);
  int len = vsnprintf(buf, 256, format, ap);
  va_end(ap);
  term->write(buf, len);
}

static void sh_banner() {
  sh_printf("Built-in Shell in NTerm (NJU Terminal)\n\n");
}

static void sh_prompt() {
  sh_printf("sh> ");
}

static void sh_handle_cmd(const char *cmd) {
  static char * args[32];
  static char buf[128];
  strcpy(buf,cmd);
  args[0]=strtok(buf," ");
  int i=1;
  static char name[32];
  while((args[i]=strtok(NULL," "))!=NULL) i++;
  for(int i=0;args[i];i++){
    int j=strlen(args[i])-1;
    while(j>=0&&args[i][j]==' '||args[i][j]=='\n') args[i][j]='\0',j--;
//    printf("%s\n",args[i]);
  }
  for(int i=0;args[0][i];i++) if(args[0][i]=='='){
    strncpy(name,args[0],i);
    setenv(name,&args[0][i+1],0);
//    printf("env:%s\n",getenv(name));
    return;
  }
  if(execvp(args[0],args)==-1) sh_printf("%s : command not found.",cmd);
  return;
}

void builtin_sh_run() {
  sh_banner();
  sh_prompt();
  setenv("PATH","/bin",0);
  while (1) {
    SDL_Event ev;
    if (SDL_PollEvent(&ev)) {
      if (ev.type == SDL_KEYUP || ev.type == SDL_KEYDOWN) {
        const char *res = term->keypress(handle_key(&ev));
        if (res) {
          sh_handle_cmd(res);
          sh_prompt();
        }
      }
    }
    refresh_terminal();
  }
}
