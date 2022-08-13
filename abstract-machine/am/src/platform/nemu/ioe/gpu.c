#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)
#define wide (uint32_t)inw(VGACTL_ADDR+2)
#define high (uint32_t)inw(VGACTL_ADDR)

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = wide, .height = high,
    .vmemsz = 0
  };
  cfg->vmemsz=cfg->width*cfg->height*sizeof(uint32_t);
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  const uint32_t *data=ctl->pixels;
  for(int i=0;i<ctl->h;i++)
  for(int j=0;j<ctl->w;j++)
  outl(((ctl->x+j)+wide*(ctl->y+i))*4+FB_ADDR,*(data++));
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
