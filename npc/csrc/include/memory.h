#define mem_start    (0x80000000uLL)
#define mem_end      (0x88000000uLL)
#define MEM_SIZE (0x8000000)
uLL pmem_read(uLL addr);
long mem_init(char * filename);
void pmem_write(uLL addr,uLL data,u8 mask);
void * mem_addr();
