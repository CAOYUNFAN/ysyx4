struct device_regs{
    const char * name;
    u64 start,end;
    void (*input) (uLL addr,uLL data,u8 mask);
    uLL (*output) (ULL addr);
};

extern const device_regs device_table[];

#define len(table) (sizeof(table)/sizeof(table[0]))
#define nr_device len(device_table)