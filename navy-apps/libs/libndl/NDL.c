#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int canvas_w = 0, canvas_h = 0;
static int dev_events;
static char buf[256];
static char buf2[128];
struct NDL_dispinfo{
  unsigned char present,has_accel;
  int width,height,vmemsz;
};
static struct NDL_dispinfo dispinfo;

uint32_t NDL_GetTicks() {
  struct timeval tv;
  gettimeofday(&tv,NULL);
  return tv.tv_usec/1000;
}

int NDL_PollEvent(char *buf, int len) {
  return read(dev_events,buf,len);
}

void NDL_OpenCanvas(int *w, int *h) {
  if (getenv("NWM_APP")) {
    int fbctl = 4;
    fbdev = 5;
    screen_w = *w; screen_h = *h;
    char buf[64];
    int len = sprintf(buf, "%d %d", screen_w, screen_h);
    // let NWM resize the window and create the frame buffer
    write(fbctl, buf, len);
    while (1) {
      // 3 = evtdev
      int nread = read(3, buf, sizeof(buf) - 1);
      if (nread <= 0) continue;
      buf[nread] = '\0';
      if (strcmp(buf, "mmap ok") == 0) break;
    }
    close(fbctl);
  }else{
    canvas_w=*w;
    canvas_h=*h;
    return;
  }
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

static inline void init_dispinfo(){
  FILE * disp_info=fopen("/proc/dispinfo","r");
  fread(buf,1,256,disp_info);
  fclose(disp_info);
  char * ch=buf;
  while (*ch){
    int data;
    sscanf(ch,"%s : %d",buf2,&data);
    if(strcmp(buf2,"PRESENT")==0) dispinfo.present=data;
    else if(strcmp(buf2,"HAS_ACCEL")==0) dispinfo.has_accel=data;
    else if(strcmp(buf2,"WIDTH")==0) dispinfo.width=data;
    else if(strcmp(buf2,"HEIGHT")==0) dispinfo.height=data;
    else if(strcmp(buf2,"VMEMSZ")==0) dispinfo.vmemsz=data;
    while(*ch&&*ch!='\n') ch++;
    ch++;
  }
  printf("dispinfo:%d,%d,%d",dispinfo.width,dispinfo.height,dispinfo.vmemsz);
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  dev_events=open("/dev/events",O_RDONLY);
  init_dispinfo();  
  return 0;
}

void NDL_Quit() {
}
