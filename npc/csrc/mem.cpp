#include<stdio.h>
#include "common.h"
#define IMEM_SIZE 4096

static uint mem[IMEM_SIZE];
uLL mem_read(uLL addr){
    return mem[(addr>>2)&(IMEM_SIZE-1)];
}