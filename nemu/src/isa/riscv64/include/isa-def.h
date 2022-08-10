#ifndef __ISA_RISCV64_H__
#define __ISA_RISCV64_H__

#include <common.h>

#define MAP_ALLCSR(f) \
  f(mepc) f(mstatus) f(mcause) f(mtvec)

typedef struct {
  word_t gpr[32];
  vaddr_t pc;
  
  #define def_csr(name) word_t name ;

  MAP_ALLCSR(def_csr)

} riscv64_CPU_state;

// decode
typedef struct {
  union {
    uint32_t val;
  } inst;
} riscv64_ISADecodeInfo;

#define isa_mmu_check(vaddr, len, type) (MMU_DIRECT)

#endif
