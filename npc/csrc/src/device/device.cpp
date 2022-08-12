#include <common.h>
#include <debug.h>
#include <memory.h>
#include <device.h>

#define DEVICE_BASE 0xa0000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)

uLL boottime=0;
extern void difftest_skip_ref();

class main_memory:public device_regs{
    public:
        void init(){name="main_memory";start=mem_start;end=mem_end;log_output();}
        uLL input(uLL addr){return pmem_read(addr);}
        void output(uLL addr,uLL data,u8 mask){pmem_write(addr,data,mask);}
}memory;

class RTC:public device_regs{
    private:
        uLL boottime;
        uLL inner_gettime(){
            timespec time;
            clock_gettime(CLOCK_MONOTONIC_COARSE,&time);
            return time.tv_sec*1000000+time.tv_nsec/1000;
        }
    public:
        void init(){
            boottime=inner_gettime();
            name="RTC";start=RTC_ADDR;end=RTC_ADDR+8;
            log_output();
        }
        uLL input(uLL addr){
            difftest_skip_ref();
            return inner_gettime()-boottime;
        }
}rtc;

class SERIAL:public device_regs{
    public:
        void init(){
            name="SERIAL";start=SERIAL_PORT;end=SERIAL_PORT+1;
            log_output();
        }
        void output(uLL addr,uLL data,u8 mask){
            difftest_skip_ref();
            Assert(mask==0x1,"Unexpected mask %x",mask);
            putchar(data);
        }
}serial;

device_regs * device_table[]={
    &memory,&rtc,&serial
};

void device_init(){
    for(int i=0;i<3;i++) device_table[i]->init();
}