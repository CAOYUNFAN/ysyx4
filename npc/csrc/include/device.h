struct device_regs{
    const char * name;
    u64 start,end;
    void (*output) (uLL addr,uLL data,u8 mask);
    uLL (*input) (uLL addr);
};

extern const device_regs device_table[];

void device_init();