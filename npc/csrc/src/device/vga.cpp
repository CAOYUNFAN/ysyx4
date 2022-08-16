#include <SDL2/SDL.h>
#include <common.h>
#include <debug.h>
#include <device.h>

static void *vmem = NULL;
static uint32_t *vgactl_port_base = NULL;

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

static void init_screen() {
  SDL_Window *window = NULL;
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(
      SCREEN_W * (MUXDEF(CONFIG_VGA_SIZE_400x300, 2, 1)),
      SCREEN_H * (MUXDEF(CONFIG_VGA_SIZE_400x300, 2, 1)),
      0, &window, &renderer);
  SDL_SetWindowTitle(window, "riscv64-npc");
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
}

static inline void update_screen() {
  SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}

void vga_update_screen() {
  // TODO: call `update_screen()` when the sync register is non-zero,
  // then zero out the sync register
  if(vgactl_port_base[1]){
//    Log("Update screen");
    update_screen();
    vgactl_port_base[1]=0;
  }
}

void init_vga() {
  vgactl_port_base = (uint32_t *)malloc(8);
  vgactl_port_base[0] = (SCREEN_W << 16) | SCREEN_H;

  vmem = malloc(SCREEN_W*SCREEN_H*sizeof(uint32_t));
  add_mmio_map("vmem", CONFIG_FB_ADDR, vmem, , NULL);
  init_screen();
  memset(vmem, 0, SCREEN_W*SCREEN_H*sizeof(uint32_t));
}
