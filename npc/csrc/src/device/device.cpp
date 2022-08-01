#include <common.h>
#include <debug.h>
#include <memory.h>
#include <device.h>

const device_regs device_table[]={
    {"memory",mem_start,mem_end,mem_read,mem_write},
    {}
}
