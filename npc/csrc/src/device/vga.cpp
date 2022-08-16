#include <SDL2/SDL.h>
#include <common.h>
#include <debug.h>
#include <device.h>

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

void init_vga() {
  SDL_Window *window = NULL;
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(800,600,0, &window, &renderer);
  SDL_SetWindowTitle(window, "riscv64-npc");
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
}

void vga_update_screen(void * vmem) {
  SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}
