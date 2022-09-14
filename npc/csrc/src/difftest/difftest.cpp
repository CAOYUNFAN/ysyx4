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

static uLL is_skip_ref_pc[6] = {};
static int num=0;
static int skip_dut_nr_inst = 0;

// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
void difftest_skip_ref() {
    uLL jmp_pc=mycpu->pc_m;
    // If such an instruction is one of the instruction packing in QEMU
    // (see below), we end the process of catching up with QEMU's pc to
    // keep the consistent behavior in our best.
    // Note that this is still not perfect: if the packed instructions
    // already write some memory, and the incoming instruction in NEMU
    // will load that memory, we will encounter false negative. But such
    // situation is infrequent.
    skip_dut_nr_inst = 0;
    for(int i=0;i<num;i++) if(is_skip_ref_pc[i]==jmp_pc) return;
    Log("num++:%llx",jmp_pc);
    is_skip_ref_pc[num++]=jmp_pc;
}

// this is used to deal with instruction packing in QEMU.
// Sometimes letting QEMU step once will execute multiple instructions.
// We should skip checking until NEMU's pc catches up with QEMU's pc.
// The semantic is
//   Let REF run `nr_ref` instructions first.
//   We expect that DUT will catch up with REF within `nr_dut` instructions.
void difftest_skip_dut(int nr_ref, int nr_dut) {
    skip_dut_nr_inst += nr_dut;

    while (nr_ref -- > 0) {
        ref_difftest_exec(1);
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

    if (skip_dut_nr_inst > 0) {
        ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
        if (ref_r.pc == npc) {
            skip_dut_nr_inst = 0;
            checkregs(&ref_r, npc);
            return;
        }
        skip_dut_nr_inst --;
        if (skip_dut_nr_inst == 0)
        panic("can not catch up with ref.pc = %llx at pc = %llx", ref_r.pc, (uLL)pc);
        return;
    }
    Log("%d\n",num);
    for(int i=0;i<num;i++) if (is_skip_ref_pc[i]==npc) {
        // to skip the checking of an instruction, just copy the reg state to reference design
        ref_difftest_regcpy(current_cpu(), DIFFTEST_TO_REF);
        --num;
        swap(is_skip_ref_pc[i],is_skip_ref_pc[num]);
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