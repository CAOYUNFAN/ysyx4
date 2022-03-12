#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "emu.h"


int main() {
  printf("Hello, ysyx!\n");
  std::shared_ptr<emu> top = std::make_shared<emu>();
  for(int i=0;i<10;++i) {
    int a = rand() & 1;
    int b = rand() & 1;
    top->a = a;
    top->b = b;
    top->eval();
    printf("a = %d, b = %d, f = %d\n", a, b, top->f);
    assert(top->f == a ^ b);
  }
  return 0;
}
