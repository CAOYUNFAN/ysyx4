#include <bits/stdc++.h>
using namespace std;

const int cache_size=2*1024*1024;
typedef unsigned long long uLL;

class cache_emu{
    private:
        uLL cache_tag[cache_size][2];
        bool valid[cache_size][2],dirty[cache_size][2],freq[cache_size];
        inline uLL addr_make(uLL tag,int index){
            return (tag<<11uLL)|((uLL)index<<4uLL);
        }
    public:
        cache_emu(){
            memset(valid,0,sizeof(valid));
        }
        void work(int index,uLL tag,int flow,bool &read, uLL &read_addr,bool &write,uLL &write_addr){
            read=write=0;
            for(int i=0;i<2;i++) if(cache_tag[index][i]==tag&&valid[index][i]){
                dirty[index][i]|=flow;
                freq[index]=i;
                return;
            }
            read=1;read_addr=addr_make(tag,index);
            for(int i=0;i<2;i++) if(!valid[index][i]){  
                cache_tag[index][i]=tag;
                valid[index][i]=1;
                dirty[index][i]=flow;
                freq[index]=i;
                return;
            }
            for(int i=0;i<2;i++) if(!dirty[index][i]){
                cache_tag[index][i]=tag;
                dirty[index][i]=flow;
                freq[index]=i;
                return;
            }
            int pos=freq[index]^1;
            freq[index]^=1;
            write=1;
            write_addr=addr_make(cache_tag[index][pos],index);
            cache_tag[index][pos]=tag;
            dirty[index][pos]=flow;
        }
}ref_cache;

void emu_cache_work(int index,uLL tag,int flow,bool &read, uLL &read_addr,bool &write,uLL &write_addr){
    ref_cache.work(index,tag,flow,read,read_addr,write,write_addr);
}