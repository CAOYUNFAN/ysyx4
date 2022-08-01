#include <common.h>
#include <debug.h>
#include <memory.h>

extern "C" void assert_check_msg(bool cond,char * msg,...){
    if(!cond){
        va_list ap;
        va_start(ap,msg);
        vprintf(msg,ap);
        va_end(ap);
        assert(0);
    }
}

