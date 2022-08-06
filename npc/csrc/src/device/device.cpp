#include <common.h>
#include <debug.h>
#include <memory.h>
#include <device.h>

#define DEVICE_BASE 0xa0000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)

uLL boottime=0;

uLL inner_gettime(){
    timespec time;
    clock_gettime(CLOCK_MONOTONIC_COARSE,&time);
    return time.tv_sec*1000000+time.tv_nsec/1000;
}

uLL timer (uLL addr){
    return inner_gettime()-boottime;
}

void kputc(uLL addr,uLL data,u8 mask){
    Assert(mask==0x1,"Unexpected mask %x",mask);
    putchar(data);
}

const device_regs device_table[]={
    {"memory"   ,mem_start  ,mem_end        ,pmem_write ,pmem_read  },
    {"RTC"      ,RTC_ADDR   ,RTC_ADDR   +8  ,NULL       ,timer      },
    {"SERIAL"   ,SERIAL_PORT,SERIAL_PORT+1  ,kputc      ,NULL       },

    {NULL,0,0,NULL,NULL}
};

void device_init(){
    boottime=inner_gettime();
}