#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t i=0;
	for(;*s++;++i);
	return i;
}

char *strcpy(char *dst, const char *src) {
  char * dest=dst;
  for(;*src;++dest,++src) *dest=*src;
  *dest='\0';
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;
	for (i = 0; i < n && src[i] != '\0'; i++)
		dst[i] = src[i];
	for ( ; i < n; i++)
		dst[i] = '\0';
	return dst;
}

char *strcat(char *dst, const char *src) {
  char * dest=dst+strlen(dst);
	for (;*src;++dest,++src)
		*dest=*src;
  *dest='\0';
	return dst;
}

int strcmp(const char *s1, const char *s2) {
  for(;*s1&&*s2;++s1,++s2) 
  if(*s1!=*s2) return *s1-*s2;

  return *s1-*s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  size_t i=0;
  for(;*s1 && *s2 && i<n; ++s1,++s2)
  if(*s1 != *s2) return *s1 - *s2;
  if(i==n) return 0;
  return *s1- *s2;
}

void *memset(void *s, int c, size_t n) {
  unsigned char uc=c;
	for(unsigned char *ss=s;n;--n,++ss) *ss=uc;
	return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  if(dst<src){
		char *a=dst;const char *b=src;
		for(;n;n--,a++,b++) *a=*b;
	}else{
		char *a=(char*)dst+n-1;char *b=(char*)src+n-1;
		for(;n;n--,a--,b--) *a=*b;
	}
	return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  char *a=out;const char *b=in;
	for(;n;n--,a++,b++) *a=*b;
	return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  const unsigned char *ss1=s1;
  const unsigned char *ss2=s2;
  for(;n;--n,++ss1,++ss2) if(*ss1!=*ss2) return *ss1<*ss2?-1:1;
  return 0;
}

#endif
