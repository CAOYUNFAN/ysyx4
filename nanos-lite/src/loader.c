#include <proc.h>
#include <elf.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
# define Elf_Shdr Elf64_Shdr
# define Elf_class ELFCLASS64
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
# define Elf_Shdr Elf32_Shdr
# define Elf_class ELFCLASS32
#endif

#if defined(__ISA_AM_NATIVE__)
# define EXPECT_TYPE EM_X86_64
#elif defined(__ISA_X86__)
# define EXPECT_TYPE EM_386
#elif defined(__ISA_MIPS32__)
# define EXPECT_TYPE EM_MIPS_X
#elif defined(__ISA_RISCV32__)
# define EXPECT_TYPE EM_RISCV
#elif defined(__ISA_RISCV64__)
# define EXPECT_TYPE EM_RISCV
#else
# error Unsupported ISA
#endif


int check_elf(const Elf_Ehdr * ehdr){
  const unsigned char * e_ident=ehdr->e_ident;
  if(e_ident[EI_MAG0]!=ELFMAG0||e_ident[EI_MAG1]!=ELFMAG1||e_ident[EI_MAG2]!=ELFMAG2||e_ident[EI_MAG3]!=ELFMAG3) return 1;
  if(e_ident[EI_CLASS]!=Elf_class){
    unsigned char t=e_ident[EI_CLASS];
    return t==ELFCLASS32||t==ELFCLASS64||t==ELFCLASSNONE?2:1;
  }
  if(e_ident[EI_DATA]!=ELFDATA2LSB){
    unsigned char t=e_ident[EI_VERSION];
    return t==ELFDATANONE||t==ELFDATA2MSB?3:1;
  }
  if(e_ident[EI_VERSION]!=EV_CURRENT) return e_ident[EI_VERSION]==EV_NONE?4:1;
  for(int i=EI_PAD;i<EI_NIDENT;i++) if(e_ident[i]!=0) return 1;
  
  if(ehdr->e_type!=ET_EXEC) return 5;
  if(ehdr->e_machine!=EXPECT_TYPE) return 6;
  return 0;
}

extern size_t ramdisk_read(void *buf, size_t offset, size_t len);
static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr ehdr;
  ramdisk_read(&ehdr,0,sizeof(Elf_Ehdr));
  int ret=check_elf(&ehdr);
  if(ret!=0) panic("Error %d exists when loading programs.",ret);
  size_t total=ehdr.e_phnum;
  if(total==PN_XNUM){
    Elf_Shdr shdr;
    ramdisk_read(&shdr,ehdr.e_shoff,sizeof(Elf_Shdr));
    total=shdr.sh_info;
  }
  for(uintptr_t addr=ehdr.e_phoff;total;addr+=ehdr.e_phentsize,total--) {
    Elf_Phdr phdr;
    ramdisk_read(&phdr,addr,sizeof(Elf_Phdr));
    if(phdr.p_type==PT_LOAD){
      ramdisk_read((void *)phdr.p_vaddr,phdr.p_offset,phdr.p_filesz);
      memset((void *)(phdr.p_vaddr+phdr.p_filesz),0,phdr.p_memsz-phdr.p_filesz);
    }
  }
  return ehdr.e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

