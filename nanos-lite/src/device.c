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

static char dispinfo[256];
static int dispinfo_len;

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  if(len>dispinfo_len-offset) len=dispinfo_len-offset;
  if(len<0) len=0;
  strncpy(buf,dispinfo+offset,len);
  return len;
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  return 0;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
  AM_GPU_CONFIG_T ev=io_read(AM_GPU_CONFIG);
  char * now=dispinfo;
  now+=sprintf(now,"PRESENT : %d\n",ev.present);
  now+=sprintf(now,"HAS_ACCEL : %d\n",ev.has_accel);
  now+=sprintf(now,"WIDTH : %d\n",ev.width);
  now+=sprintf(now,"HEIGHT : %d\n",ev.height);
  now+=sprintf(now,"VMEMSZ : %d\n",ev.vmemsz);
  dispinfo_len=strlen(now);
}
