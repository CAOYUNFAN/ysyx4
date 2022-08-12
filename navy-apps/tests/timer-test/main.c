#include <stdio.h>
#include <NDL.h>
#include <sys/time.h>
#include <assert.h>

#ifdef TIMER_USE_NDL
#define gap 1000
#define fmt "%d.%03d"
#else
#define gap 1000000
#define fmt "%d.%06d"
#endif

int get_time(){
    #ifdef TIMER_USE_NDL
    return NDL_GetTicks();
    #else
    struct timeval tv;
    assert(gettimeofday(&tv,NULL)==0);
    return tv.tv_usec;
    #endif
}

int main(){
    printf("timer_test start!\n");
    int now=get_time(),i=0;
    while (1){
        while(get_time()-now<gap/100000);
        now=get_time();
        printf("timer test:%d time, " fmt,i,now/gap,now%gap);
        i++;
    }
}