#define ASNI_NONE       "\33[0m"
#define ASNI_FG_RED     "\33[1;31m"
#define ASNI_FG_BLUE    "\33[1;34m"
#define ASNI_FMT(str, fmt) fmt str ASNI_NONE

extern void reg_display();

#define _Log(...) \
    fprintf(stderr, __VA_ARGS__); 

#define _Log2(...) \
    do{\
        extern FILE * Log_file;\
        if(Log_file){\
            fprintf(Log_file,__VA_ARGS__);\
            fflush(Log_file);\
        }\
    } while (0)
    
#define Log(format, ...) \
    do{\
        _Log(ASNI_FMT("[%s:%d %s] " format, ASNI_FG_BLUE) "\n", \
            __FILE__, __LINE__, __func__, ## __VA_ARGS__);\
        _Log2("[%s:%d %s]" format "\n", \
            __FILE__, __LINE__, __func__, ## __VA_ARGS__);\
    } while(0)
    

#define Assert(cond, format, ...) \
    do { \
        if (!(cond)) { \
            fprintf(stderr, ASNI_FMT("[%s:%d %s]" format, ASNI_FG_RED) "\n", __FILE__,__LINE__,__func__,##  __VA_ARGS__); \
            _Log2("[%s:%d %s]" format "\n", \
                __FILE__, __LINE__, __func__, ## __VA_ARGS__);\
            \
            reg_display();\
            assert(cond); \
        } \
    } while (0)

#define panic(format, ...) Assert(0, format, ## __VA_ARGS__)

#define RANGE(addr,start,end)\
    if((addr)<start||(addr)>end){\
        fprintf(stderr,"Unexpected Addr %p!\n",(void *)(addr));\
        assert((addr)>=start&&(addr)<=end);\
    }
