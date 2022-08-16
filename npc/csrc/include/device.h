class device_regs{
    protected:
        const char * name;
        uLL start,end;
        inline void log_output(){
            Log("device %s is mapped to [ 0x%llx , 0x%llx )",name,start,end);
        }
    public:
        inline bool in_range(uLL addr) {return addr>=start&&addr<end;}
        virtual void init(){panic("TODO!");}
        virtual uLL input(uLL addr) {panic("device_reg %s cannot be read!",name);return 114514;}
        virtual void output(uLL addr,uLL data,u8 mask) {panic("device_reg %s cannot be write!",name);}
};

extern device_regs * device_table[];

void device_init();

#define SCREEN_W 400
#define SCREEN_H 300
