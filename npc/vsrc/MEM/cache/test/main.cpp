#include <bits/stdc++.h>
#include "emu_cache.h"
using namespace std;
typedef long long LL;
typedef unsigned long long uLL;

uint seed;
emu_cache * emu;
uLL myrandom(){
    return (uLL)rand()*(uLL)rand()*(uLL)rand()*(uLL)rand();
}

const int N=1000000;

const uLL mem_start=0x80000000,mem_size=0x8000000;
uLL big_mem[mem_size/8];

#define Assert(cond,fmt,...)\
    if(!(cond)){\
        printf("[%d %s]" fmt, __LINE__, __func__, ## __VA_ARGS__);\
        printf("seed=%u\n",seed);\
        return 1;\
    }
//#define DEBUG
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

extern void emu_cache_work(int index,uLL tag,int flow,bool &read, uLL &read_addr,bool &write,uLL &write_addr);
int main(){
    seed=unsigned(time(0));
    srand(seed);
    printf("%u\n",seed);
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
    for(int i=0;i<N;i++){
        emu->valid=1;
        emu->op=rand()%2;
        uLL addr=random()%mem_size+mem_start;
        emu->offset=addr>>3&1;
        emu->index=addr>>4&((1<<7)-1);
        emu->tag=addr>>11;
        if(emu->op){
            emu->wstrb=rand()&((1<<8)-1);
            emu->wdata=random();
            update(addr,emu->wstrb,emu->wdata);
            Log("%2d:Write addr=%llx,data=%lx\n",i,addr,emu->wdata);
        }else Log("%2d:Read addr=%llx\n",i,addr);
        int read_num=rand()%8+1;
        int write_num=rand()%8+1;
        Log("readnum %d,writenum %d\n",read_num,write_num);
        int tt=0;
        bool read,write;
        uLL read_addr=0,write_addr=0;
        emu_cache_work(emu->index,emu->tag,emu->op,read,read_addr,write,write_addr);
        do{
            CYCLE_ONE();
            if(emu->wr_req){
                Assert(write,"should not write!");
                uLL low=(uLL)emu->wr_data[0]|((uLL)emu->wr_data[1]<<32uLL);
                uLL high=(uLL)emu->wr_data[2]|((uLL)emu->wr_data[3]<<32uLL);
                assert((emu->wr_addr&0xf)==0);
                Assert(emu->wr_addr==write_addr,"Unexpected write addr %lx,should be %llx\n",emu->wr_addr,write_addr);
                uLL addr=(emu->wr_addr-mem_start)>>3;
                if(low!=big_mem[addr]){
                    Log("FAIL on addr %llx:write in %llx,expected %llx\n",addr,low,big_mem[addr]);
                    return 1;
                }
                if(high!=big_mem[addr|1]){
                    Log("FAIL on addr %llx:write in %llx,expected %llx\n",addr|1,high,big_mem[addr|1]);
                    return 1;
                }
                Log("Write to memory %d,%lx\n",write_num,emu->wr_addr);
                assert(write_num>=0); 
                write_num--;
            }
            if(emu->rd_req||(emu->wr_req&&write_num==0)){
                Assert(read,"should not read!");
                assert((emu->rd_addr&0xf)==0);
                Assert(emu->rd_addr==read_addr,"Unexpected read addr %lx,should be %llx\n",emu->rd_addr,read_addr);
                if(read_num==1){
                    emu->rd_valid=1;
                    uLL addr=(emu->rd_addr-mem_start)>>3;
                    emu->rd_data[0]=big_mem[addr];
                    emu->rd_data[1]=big_mem[addr]>>32uLL;
                    emu->rd_data[2]=big_mem[addr|1];
                    emu->rd_data[3]=big_mem[addr|1]>>32uLL;
                }
                Log("Read from memory %d,%lx\n",read_num,emu->rd_addr);
                Assert(read_num>=0,"readnum < 0!\n");
                if(!read_num) emu->rd_ready=0;
                read_num--;
            }
            emu->rd_ready=((emu->rd_req||(emu->wr_req&&write_num==0))&&read_num==0);
            emu->wr_ready=(emu->wr_req&&write_num==0);
            tt++;
        } while (!emu->ok && tt<=20);
        CYCLE_ONE();
        if(tt>20) {
            Log("TOO MUCH CYCLES!\n");
            return 1;
        }
        if(!emu->op){
            if(big_mem[(addr-mem_start)>>3]!=emu->rdata){
                Log("FAIL ON addr %llx,read %lx,expected %llx",addr,emu->rdata,big_mem[addr>>3]);
                return 1;    
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
    printf("PASSED!\n");
    return 0;
}