#include <bits/stdc++.h>
using namespace std;

const uint32_t cache_size=32;
typedef vector<uint32_t> vu;

class cache_emu{
    private:
        uint32_t cache_tag[cache_size][2];
        bool valid[cache_size][2],dirty[cache_size][2],freq[cache_size];
        inline uint32_t addr_make(uint32_t tag,uint32_t index,uint32_t offset=0){
            return (tag<<11u)|(index<<6u)|offset;
        }
    public:
        cache_emu(){
            memset(valid,0,sizeof(valid));
            memset(freq,0,sizeof(freq));
        }
        void work(uint32_t index,uint32_t tag,uint32_t offset,uint32_t flow,bool &read, uint32_t &read_addr,bool &write,uint32_t &write_addr){
            read=write=0;
            if(tag<(1<<20)){
                read=flow^1;
                write=flow;
                read_addr=write_addr=addr_make(tag,index);
                return;
            }
            for(uint32_t i=0;i<2;i++) if(cache_tag[index][i]==tag&&valid[index][i]){
                dirty[index][i]|=flow;
                freq[index]=i;
                return;
            }
            read=1;read_addr=addr_make(tag,index);
            for(uint32_t i=0;i<2;i++) if(!valid[index][i]){  
                cache_tag[index][i]=tag;
                valid[index][i]=1;
                dirty[index][i]=flow;
                freq[index]=i;
                return;
            }
            if(dirty[index][0]!=dirty[index][1])
            for(uint32_t i=0;i<2;i++) if(!dirty[index][i]){
                cache_tag[index][i]=tag;
                dirty[index][i]=flow;
                freq[index]=i;
                return;
            }
            uint32_t pos=freq[index]^1;
            freq[index]^=1;
            write=dirty[index][pos];
            write_addr=addr_make(cache_tag[index][pos],index);
            cache_tag[index][pos]=tag;
            dirty[index][pos]=flow;
        }
        vu * fence(){
            static vu ret;
            ret.clear();
            for(uint32_t i=0;i<cache_size;i++)
            for(uint32_t j=0;j<2;j++)if(valid[i][j]&&dirty[i][j]){
                ret.push_back(addr_make(cache_tag[i][j],i));
                dirty[i][j]=0;
            }
            return &ret;
        }
}ref_cache;

void emu_cache_work(uint32_t index,uint32_t tag,uint32_t offset,uint32_t flow,bool &read, uint32_t &read_addr,bool &write,uint32_t &write_addr){
    ref_cache.work(index,tag,offset,flow,read,read_addr,write,write_addr);
}

vu * emu_cache_fence(){
    return ref_cache.fence();
}