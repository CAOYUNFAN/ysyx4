#include <fs.h>

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  ReadFn read;
  WriteFn write;
  size_t open_offset;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

/* This is the information about all files in disk. */
extern size_t serial_write(const void *buf, size_t offset, size_t len);

static Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, serial_write},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, serial_write},
#include "files.h"
};

#define file_num LENGTH(file_table)

int fs_open(const char *pathname, int flags, int mode){
  Log("open file %s",pathname);
  for(int i=0;i<file_num;i++) if(strcmp(file_table[i].name,pathname)==0){
    file_table[i].open_offset=0;
    return i;
  }
  panic("file %s do not exist!",pathname);
  return -1;
}

size_t fs_read(int fd, void *buf, size_t len){
  if(fd<0||fd>=file_num) return -1;
  Finfo * file=&file_table[fd];
  if(file->read){
    len=file->read(buf,file->open_offset,len);
    file->open_offset+=len;
    return len;
  }

  size_t left=file->size-file->open_offset;
  if(left<len) len=left;

  ramdisk_read(buf,file->disk_offset+file->open_offset,len);
  file->open_offset+=len;
  return len;
}

size_t fs_write(int fd, const void *buf, size_t len){
  if(fd<0||fd>=file_num) return -1;
  Finfo * file=&file_table[fd];
  if(file->write) {
    len=file->write(buf,file->open_offset,len);
    file->open_offset+=len;
    return len;
  }

  size_t left=file->size-file->open_offset;
  if(left<len) len=left;

  ramdisk_write(buf,file->disk_offset+file->open_offset,len);
  file->open_offset+=len;
  return len;
}

size_t fs_lseek(int fd, size_t offset, int whence){
  if(fd<0||fd>=file_num) return -1;
  Finfo * file=&file_table[fd];

  switch(whence){
    case SEEK_SET:file->open_offset=offset;break;
    case SEEK_CUR:file->open_offset+=offset;break;
    case SEEK_END:file->open_offset=file->size+offset;break;
    default:return -1;
  }

  if(file->open_offset>=0&&file->open_offset<=file->size) return file->open_offset;
  return -1;
}

int fs_close(int fd){
  return 0;
}

void init_fs() {
  // TODO: initialize the size of /dev/fb
}
