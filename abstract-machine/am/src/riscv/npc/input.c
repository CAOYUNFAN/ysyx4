#include <am.h>

#define KBD_ADDR        (0xa0000000 + 0x0000060)
#define KEYDOWN_MASK 0x8000

static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t data=inl(KBD_ADDR);
  kbd->keydown = (data&KEYDOWN_MASK);
  kbd->keycode = data&(KEYDOWN_MASK-1);
}
