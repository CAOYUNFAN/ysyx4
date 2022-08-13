#include <common.h>
#include <device.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  const char * ch=buf;
  for(int i=0;i<len;i++,ch++) putch(*ch);
  return len;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  if(ev.keycode== AM_KEY_NONE) return 0;
  snprintf(buf,len,"k%c %s",ev.keydown?'d':'u',keyname[ev.keycode]);
  return strlen(buf);
}

static char dispinfo[128];
static int dispinfo_len;
AM_GPU_CONFIG_T disp_info;

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  if(len>dispinfo_len-offset) len=dispinfo_len-offset;
  if(len<0) len=0;
  memcpy(buf,dispinfo+offset,len);
  return len;
}

static inline void dispinfo_init(){
  disp_info=io_read(AM_GPU_CONFIG);
  char * now=dispinfo;
  now+=sprintf(now,"PRESENT : %d\n",disp_info.present);
  now+=sprintf(now,"HAS_ACCEL : %d\n",disp_info.has_accel);
  now+=sprintf(now,"WIDTH : %d\n",disp_info.width);
  now+=sprintf(now,"HEIGHT : %d\n",disp_info.height);
  now+=sprintf(now,"VMEMSZ : %d\n",disp_info.vmemsz);
  dispinfo_len=strlen(dispinfo)+1;
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  offset/=sizeof(uint32_t);
  size_t w=disp_info.width;
  io_write(AM_GPU_FBDRAW,offset%w,offset/w,buf,len/sizeof(uint32_t),true);
  return len;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
  dispinfo_init();
}
