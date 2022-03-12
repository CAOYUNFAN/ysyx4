#include<stdio.h>
typedef unsigned long long uLL;
typedef unsigned int uint;
#define IMEM_SIZE 4096

static uint imem[IMEM_SIZE];
uint imem_read(uLL pc){
    return imem[(pc>>2)&(IMEM_SIZE-1)];
}