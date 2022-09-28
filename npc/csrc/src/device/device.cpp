#include <common.h>
#include <debug.h>
#include <memory.h>
#include <device.h>

#define DEVICE_BASE 0x20000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define FB_ADDR         (DEVICE_BASE + 0x1000000)
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)

uLL boottime=0;
extern void difftest_skip_ref();

class main_memory:public device_regs{
    public:
        void init(){name="main_memory";start=mem_start;end=mem_end;log_output();}
        void input(uLL addr,uLL * rdata,u8 * error){*rdata=pmem_read(addr);*error=0;}
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
        void input(uLL addr,uLL * rdata,u8 * error){
            difftest_skip_ref();
            *rdata=inner_gettime()-boottime;
            *error=0;
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
            //Assert(mask==0x1,"Unexpected mask %x",mask);
            putchar(data);
        }
}serial;

class FB:public device_regs{
    private:
        union{
            u8 _8[8];
        } vmem[SCREEN_W*SCREEN_H/2];
    public:
        void init(){
            name="FB";start=FB_ADDR;end=FB_ADDR+sizeof(vmem);
            log_output();
            memset(vmem,0,sizeof(vmem));
            vga_update_screen(vmem);
        }
        void output(uLL addr,uLL data,u8 mask){
            difftest_skip_ref();
            addr=(addr-FB_ADDR)>>3;
            for(int i=0;i<8;i++) if(mask&(1<<i)){
                vmem[addr]._8[i]=data&0xff;
                data>>=8;
            }
        }
        void * pointer(){return &vmem[0];}
}fb;

class VGA_CTL:public device_regs{
    private:
        union{
            u8 _8[8];
            u16 _16[4];
            u32 _32[2];
            u64 _64;
        }mem;
    public:
        void init(){
            name="VGA_CTL";start=VGACTL_ADDR;end=VGACTL_ADDR+8;
            log_output();
            mem._16[0]=SCREEN_H;
            mem._16[1]=SCREEN_W;
            mem._32[1]=0;
        }
        void input(uLL addr,uLL * rdata,u8 * error){
            difftest_skip_ref();
            *rdata=mem._64;
            *error=0;
        }
        void output(uLL addr,uLL data,u8 mask){
            difftest_skip_ref();
            //assert(mask==0xf0);
            if(data) vga_update_screen(fb.pointer());
        }
}vga_ctl;

class KEYBOARD:public device_regs{
    public:
        void init(){
            name="KEYBOARD";start=KBD_ADDR;end=KBD_ADDR+4;
            log_output();
        }
        void input(uLL addr,uLL * rdata,u8 * error){
            difftest_skip_ref();
            *rdata=key_dequeue();
            *error=0;
        }
}kbd;

class INIT: public device_regs{
    public:
        void init(){
            name="INIT";start=0x30000000;end=0x30000008;
        }
        void input(uLL addr,uLL *rdata, u8 * error){
            *error=0;
            *rdata=0x806750000097uLL;
        }
}init;

device_regs * device_table[]={
    &memory,&rtc,&serial,&vga_ctl,&fb,&kbd,&init
};

void device_init(){
    init_vga();
    init_keymap();
    for(int i=0;i<7;i++) device_table[i]->init();
}

void device_update(){
    keyboard_update();
}

void data_read(uLL addr,unsigned long * data,u8 * error){
    #ifdef MTRACE
    Log("read from addr %llx",addr);
    #endif
    for(int i=0;i<7;i++) if(device_table[i]->in_range(addr)) {
        uLL data_local;
        device_table[i]->input(addr,&data_local,error);
        *data=data_local;
        return;
    }
    *error=1;*data=1145141919810uLL;
    return;
}

void data_write(uLL addr,unsigned long *data,u8 mask, u8 * error){
    *error=0;
    #ifdef MTRACE
    Log("write to addr %llx",addr);
    #endif
    for(int i=0;i<7;i++) if(device_table[i]->in_range(addr)){
        device_table[i]->output(addr,*data,mask);
        return;
    }
    panic("Unexpected write addr %llx",addr);
}