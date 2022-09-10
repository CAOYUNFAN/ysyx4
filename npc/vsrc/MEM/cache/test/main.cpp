#include <bits/stdc++.h>
#include "emu_cache.h"
using namespace std;
typedef long long LL;
typedef unsigned long long uLL;
typedef vector<uint32_t> vu;

uint seed;
emu_cache * emu;
uLL myrandom(){
    return (uLL)rand()*(uLL)rand()*(uLL)rand()*(uLL)rand();
}

const int N=1000,M=100;

const uint32_t mem_start=0x80000000,mem_size=0x8000000;
uLL big_mem[mem_size/8];

#define FORCE_END\
    printf("seed=%u\n",seed);exit(1);

#define Assert(cond,fmt,...)\
    if(!(cond)){\
        printf("[%d %s]" fmt, __LINE__, __func__, ## __VA_ARGS__);\
        FORCE_END\
    }

#ifdef DEBUG
#define Log(fmt,...)  printf("[%d %s]" fmt, __LINE__, __func__, ## __VA_ARGS__)
#else
#define Log(fmt,...) ((void)0)
#endif

void CYCLE_ONE(){
    Log("DOWN!\n");
    emu->clk=0;
    emu->eval();
    Log("UP!\n");
    emu->clk=1;
    emu->eval();
}

union my{
    uint8_t _8[8];
    uLL _64;
};

void update(uLL addr,uint8_t wstrb,uLL data){
    my xx,yy;
    xx._64=big_mem[(addr-mem_start)>>3];
    yy._64=data;
    for(int i=0;i<8;i++) if(wstrb>>i&1) xx._8[i]=yy._8[i];
    big_mem[(addr-mem_start)>>3]=xx._64;
}

extern void emu_cache_work(uint32_t index,uint32_t tag,uint32_t flow,bool &read, uint32_t &read_addr,bool &write,uint32_t &write_addr);
extern vu * emu_cache_fence();

const int LEN=512;

void test_1(){
    for(int i=0;i<N;i++){
        emu->valid=1;
        emu->op=rand()%2;
        uint32_t addr=mem_start+random()%mem_size;
        emu->offset=(addr>>3)&((1<<3)-1);
        emu->index=(addr>>6)&((1<<5)-1);
        emu->tag=addr>>11;
        if(emu->op){
            emu->wstrb=rand()&((1<<8)-1);
            emu->wdata=random();
            update(addr,emu->wstrb,emu->wdata);
            Log("%d:Write addr=%x,data=%lx,mask=%x\n",i,addr,emu->wdata,emu->wstrb);
        }else Log("%d:Read addr=%x\n",i,addr);
        int read_num=rand()%8+1;
        int write_num=rand()%8+1;
        Log("readnum %d,writenum %d\n",read_num,write_num);
        int tt=0;
        bool read,write;
        uint32_t read_addr=0,write_addr=0;
        emu_cache_work(emu->index,emu->tag,emu->op,read,read_addr,write,write_addr);
        do{
            CYCLE_ONE();
            Assert(!emu->rd_req||!emu->wr_req,"Read and write flags raise up at the same time!");
            if(emu->wr_req){
                Assert(write,"should not write!");
                assert((emu->addr&0xf)==0);
                Assert(emu->addr==write_addr,"Unexpected write addr %x,should be %x\n",emu->addr,write_addr);
                uint32_t addr=(emu->addr-mem_start)>>3;
                for(int i=0;i<LEN/64;i++){
                    uLL data=(uLL)emu->wr_data[i<<1]|((uLL)emu->wr_data[(i<<1)|1]<<32uLL);
                    if(data!=big_mem[addr+i]){
                        Log("FAIL on addr %x:write in %llx,expected %llx\n",emu->addr+(i<<3),data,big_mem[addr+i]);
                        FORCE_END
                    }
                }
                Log("Write to memory %d,%x\n",write_num,emu->addr);
                assert(write_num>=0); 
                write_num--;
            }
            if(emu->rd_req){
                Assert(read,"should not read!");
                assert((emu->addr&0xf)==0);
                Assert(emu->addr==read_addr,"Unexpected read addr %x,should be %x\n",emu->addr,read_addr);
                if(read_num==1){
                    emu->rd_valid=1;
                    uint32_t addr=(emu->addr-mem_start)>>3;
                    for(int i=0;i<LEN/64;i++){
                        emu->rd_data[i<<1]=big_mem[addr+i];
                        emu->rd_data[(i<<1)|1]=big_mem[addr+i]>>32uLL;
                        Log("read data %d:%llx\n",i,big_mem[addr+i]);
                    }
                }
                Log("Read from memory %d,%x\n",read_num,emu->addr);
                Assert(read_num>=0,"readnum < 0!\n");
                if(!read_num) emu->rd_ready=0;
                read_num--;
            }
            emu->rd_ready=(emu->rd_req&&read_num==0);
            emu->wr_ready=(emu->wr_req&&write_num==0);
            tt++;
        } while (!emu->ok && tt<=20);
        Log("Read or write complete! one more cycle\n");
        if(read||write) CYCLE_ONE();
        if(tt>20) {
            Log("TOO MUCH CYCLES!\n");
            FORCE_END
        }
        Log("DONE! checking...\n");
        if(!emu->op){
            if(big_mem[(addr-mem_start)>>3]!=emu->rdata){
                Log("FAIL ON addr %x,read %lx,expected %llx\n",addr,emu->rdata,big_mem[(addr-mem_start)>>3]);
                FORCE_END    
            }
            assert(~emu->rw_error);
        }
        Log("COMPLETE!\n");
        emu->valid=0;
        int left_empty=rand()%4;
        for(int i=0;i<left_empty;i++){
            assert(!emu->rd_req&&!emu->wr_req);
            CYCLE_ONE();
        }
    }
}

int main(){
    seed=unsigned(time(0));
    srand(seed);
    emu=new emu_cache();
    for(int i=0;i<mem_size/8;i++) big_mem[i]=myrandom();
    emu->clk=0;
    emu->rst=1;
    emu->eval();
    emu->clk=1;
    emu->eval();
    emu->rst=0;
    emu->fence=0;
    printf("hello!\n");
    printf("seed=%u\n",seed);
    for(int _=0;_<M;_++){
        test_1();
        emu->fence=1;
        emu->valid=0;
        Log("BIGCCYLE %d completed!\n",_);
        vu * mylist=emu_cache_fence();
        int wait=rand()%8+1;
        auto now=mylist->begin();
        Log("wait %d\n",wait);
        do{
            CYCLE_ONE();
            if(emu->wr_req){
                Assert(now!=mylist->end()&&emu->addr==*now,"Unexpected addr=%x,ref=%x\n",emu->addr,now==mylist->end()?0xffff:*now);
                uint32_t addr=(emu->addr-mem_start)>>3;
                for(int i=0;i<8;i++){
                    uLL data=(uLL)emu->wr_data[i<<1]|((uLL)emu->wr_data[(i<<1)|1]<<32uLL);
                    if(data!=big_mem[addr+i]){
                        Log("FAIL on addr %x:write in %llx,expected %llx\n",emu->addr+(i<<3),data,big_mem[addr+i]);
                        FORCE_END
                    }
                }
                if(wait==1){
                    emu->wr_ready=1;
                    wait=rand()%8+1;
                    now++;
                    Log("wait %d\n",wait);
                }
                else wait--,emu->wr_ready=0;
            }else emu->wr_ready=0;
        } while (!emu->ready);
        emu->fence=0;
        Log("fence %d ended!\n",_);
    }
    printf("PASSED!\n");
    return 0;
}