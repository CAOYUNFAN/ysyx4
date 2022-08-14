#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int canvas_w = 0, canvas_h = 0;
static int dev_events;
static char buf[256],buf2[128];
struct NDL_dispinfo{
  unsigned char present,has_accel;
  int vmemsz;
};
static struct NDL_dispinfo dispinfo;
static FILE * dev_fb;

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
    if(*w==0&&*h==0){
      *w=screen_w;
      *h=screen_h;
    }
    canvas_w=*w;
    canvas_h=*h;
    return;
  }
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  assert(x+w<=canvas_w);assert(y+h<=canvas_h);
  x+=(screen_w-canvas_w)/2;y+=(screen_h-canvas_h)/2;
  uint32_t offset=(y*screen_w+x)*sizeof(uint32_t);
  for(int i=0;i<h;i++){
    fseek(dev_fb,offset,SEEK_SET);
    fwrite(pixels,sizeof(uint32_t),w,dev_fb);
    pixels+=w;
    offset+=screen_w*sizeof(uint32_t);
  }
  fflush(dev_fb);
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
  fread(buf,1,128,disp_info);
  fclose(disp_info);
  char * ch=buf;
  while (*ch){
    int data;
    sscanf(ch,"%s : %d",buf2,&data);
    if(strcmp(buf2,"PRESENT")==0) dispinfo.present=data;
    else if(strcmp(buf2,"HAS_ACCEL")==0) dispinfo.has_accel=data;
    else if(strcmp(buf2,"WIDTH")==0) screen_w=data;
    else if(strcmp(buf2,"HEIGHT")==0) screen_h=data;
    else if(strcmp(buf2,"VMEMSZ")==0) dispinfo.vmemsz=data;
    while(*ch&&*ch!='\n') ch++;
    ch++;
  }
  printf("dispinfo:%d,%d,%d\n",screen_w,screen_h,dispinfo.vmemsz);
  memset(buf,0xff,sizeof(buf));
  int total=dispinfo.vmemsz;
  while(total){
    int size=sizeof(buf);if(size>total) size=total;total-=size;
    fseek(dev_fb,-total,SEEK_END);
    fwrite(buf,1,size,dev_fb);
    printf("%ld %d\n",ftell(dev_fb),size);
  }
  fflush(dev_fb);
  printf("init ended!\n");
//  printf("%s\n",buf);
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  dev_events=open("/dev/events",O_RDONLY);
  dev_fb=fopen("/dev/fb","w");
  init_dispinfo();
  return 0;
}

void NDL_Quit() {
  fclose(dev_fb);
}
