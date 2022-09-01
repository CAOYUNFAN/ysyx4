#include <bits/stdc++.h>
#include "emu_div.h"
using namespace std;
typedef long long LL;
typedef unsigned long long uLL;

const int N=1000000;
uLL ramdom(){
    return (uLL)rand()*(uLL)rand()*(uLL)rand()*(uLL)rand();
}

emu_div * emu;

uLL check(uLL x,uLL y,int aluctr,int is_w){
    unsigned xx=(unsigned)x,yy=(unsigned)y;
    switch (aluctr) {
        case 0:return (uLL)(is_w?(int)xx/(int)yy:(LL)x/(LL)y);
        case 1:return (uLL)(is_w?xx/yy:x/y);
        case 2:return (uLL)(is_w?(int)xx%(int)yy:(LL)x%(LL)y);
        default:return (uLL)(is_w?xx%yy:x%y);
    }
}

int main(){
    srand(unsigned(time(0)));
    emu=new emu_div;
    printf("HELLO!\n");
    emu->rst=1;
    emu->clk=0;
    emu->eval();
    emu->clk=1;
    emu->eval();
    emu->clk=0;
    emu->eval();
    emu->rst=0;
    for(int i=0;i<N;i++){
        uLL x=ramdom(),y=ramdom();
        while(y==0) y=ramdom();
        int aluctr=rand()%4;
        int is_w=rand()&1;
        emu->src1_in=x;emu->src2_in=y;emu->ALUctr_in=aluctr;emu->is_w=is_w;emu->in_valid=1;
        assert(emu->in_ready);
        int num=0;
        do{
            emu->clk=1;
            emu->eval();
            emu->clk=0;
            emu->eval();
            emu->in_valid=0;
            num++;
        } while (!emu->out_valid||num>67);
        if(!emu->out_valid||emu->result!=check(x,y,aluctr,is_w)){
            if(!emu->out_valid) printf("TOO MUCH cycles!\n");
            printf("x=%llx,y=%llx,aluctr=%d,is_w=%d,ans=%lx,ref=%llx\n",x,y,aluctr,is_w,emu->result,check(x,y,aluctr,is_w));
            return 1;
        }
        assert(emu->in_ready);
        num=ramdom()%3;
        for(int i=0;i<=num;i++){
            emu->clk=1;
            emu->eval();
            emu->clk=0;
            emu->eval();
            assert(emu->in_ready);
        }
    }
    printf("PASSED!\n");
    return 0;
}