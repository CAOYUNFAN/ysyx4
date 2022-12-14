#include <common.h>
#include <debug.h>
#include <kernel.h>
#include <memory.h>

#include <dlfcn.h>
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

void (*ref_difftest_memcpy)(uLL addr, void *buf, unsigned long n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;
#define RESET_VECTOR 0x80000000

extern int is_difftest;

void init_difftest(char * ref_so_file, unsigned long img_size){
    assert(ref_so_file != NULL);

    void *handle;
    handle = dlopen(ref_so_file, RTLD_LAZY | RTLD_DEEPBIND );
    assert(handle);

    ref_difftest_memcpy = (void (*)(uLL addr, void *buf, unsigned long n, bool direction)) dlsym(handle, "difftest_memcpy");
    assert(ref_difftest_memcpy);

    ref_difftest_regcpy = (void (*)(void *dut, bool direction)) dlsym(handle, "difftest_regcpy");
    assert(ref_difftest_regcpy);

    ref_difftest_exec = (void (*)(unsigned long))dlsym(handle, "difftest_exec");
    assert(ref_difftest_exec);

    ref_difftest_raise_intr = (void (*)(unsigned long))dlsym(handle, "difftest_raise_intr");
    assert(ref_difftest_raise_intr);

    void (*ref_difftest_init)(int) = (void (*)(int))dlsym(handle, "difftest_init");
    assert(ref_difftest_init);

    Log("Differential testing: %s", "ON");
    Log("The result of every instruction will be compared with %s. "
        "This will help you a lot for debugging, but also significantly reduce the performance. "
        "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

    ref_difftest_init(0);
    ref_difftest_memcpy(RESET_VECTOR, mem_addr(), img_size, DIFFTEST_TO_REF);
    ref_difftest_regcpy(current_cpu(), DIFFTEST_TO_REF);
}

static uLL is_skip_ref_pc[6] = {0x30000004,0x80000000};
static int num=2;
static int skip_dut_nr_inst = 0;

// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
void difftest_skip_ref() {
    if(is_difftest){
        extern uint64_t *pc_m;
        uLL jmp_pc=*pc_m;
        skip_dut_nr_inst = 0;
        is_skip_ref_pc[num++]=jmp_pc;
    }
}

static void checkregs(CPU_state *ref, uLL pc) {
    if (!difftest_checkregs(ref, pc)) {
        panic("NOT the same!");
    }
}

static int difftest_enabled=1;
void difftest_step(uLL pc, uLL npc) {
    if(!difftest_enabled) return;
    CPU_state ref_r;

    for(int i=0;i<num;i++) if (is_skip_ref_pc[i]==npc) {
        //Log("%d:%llx is skipped.",num,npc);
        // to skip the checking of an instruction, just copy the reg state to reference design
        ref_difftest_regcpy(current_cpu(), DIFFTEST_TO_REF);
        swap(is_skip_ref_pc[i],is_skip_ref_pc[--num]);
        //Log("pc=%llx,nxt=%lx",npc,mycpu->pc_nxt);
        return;
    }
    ref_difftest_exec(1);
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    checkregs(&ref_r, npc);
}

void disable_difftest(){difftest_enabled=0;}
void enable_difftest(){
    difftest_enabled=1;
    ref_difftest_memcpy(RESET_VECTOR, mem_addr(), MEM_SIZE, DIFFTEST_TO_REF);
    ref_difftest_regcpy(current_cpu(), DIFFTEST_TO_REF);
}
