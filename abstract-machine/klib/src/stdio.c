#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static const char num_table[]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

#define read_num(fmt,data) {\
	while(*(fmt)>='0'&&*(fmt)<='9') data = (data) *10 +*(fmt) -'0',++fmt;\
}

inline static char* num_to_str(char *st,int d,bool positive){
	if(d==0){*st++='0';return st;}
	if(d>=0&&positive) {*st++='+';}
	if(d<0){*st++='-';d=-d;}
	char temp[30];
	int top=0;
	for(;d;d/=10) temp[++top]=d%10+'0';
	while(top) *st++=temp[top--];
	return st;
}

inline static char* unum_to_str(char *st,unsigned int d,int base){
	if(d==0){*st++='0';return st;}
	char temp[30];
	int top=0;
	for(;d;d/=base) temp[++top]=num_table[d%base];
	while(top) *st++=temp[top--];
	return st;
}

#define MAX_NUM_stdio (1<<20)
static char temp[MAX_NUM_stdio];


int printf(const char *fmt, ...) {
  va_list ap; va_start(ap,fmt);
	int len=vsprintf(temp,fmt,ap);
	va_end(ap);
	putstr(temp);
	return len;
}


#define cao_arg(d,ap,ch) switch(ch){\
 case 'l':d=va_arg(ap,intptr_t);break;\
 case 'L':d=va_arg(ap,int64_t);break;\
 case 'h':\
 default: d=va_arg(ap,int);break;\
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  int d;char c;char *st=out;char* s;
	while(*fmt){
		if(*fmt!='%'){
			*st++=*fmt++;
			continue;
		}
		int tag;

		enum flags_type{
			notype,
			zero=1,
			left=2,
			positive=4,
			empty=8,
			sharp=16
		};
		size_t flags=notype;
		tag=0;
		while(!tag){
			switch (*(++fmt)){
				case '-':flags|=left;break;
				case '+':flags|=positive;break;
				case ' ':flags|=empty;panic("Not Implemented or Error happens!");break;
				case '#':flags|=sharp;panic("Not Implemented or Error happens!");break;
				case '0':flags|=zero;break;
				default:tag=1;break;
			}
		}

		size_t width=0;
		if(*fmt>='0'&&*fmt<='9') read_num(fmt,width)
		else if(*fmt=='*'){
			width=va_arg(ap,int);
			if(width<0) flags|=left,width=-width;
			++fmt;
		};


		if(*fmt=='.') panic("Not Support float or Error happens!");

		char length=' ';
		if(*fmt=='h'||*fmt=='l'||*fmt=='L'||*fmt=='Z'||*fmt=='z'){
			length=*(fmt++);
			if(length=='l'&&*fmt=='l'){
				length='L';
				++fmt;
				panic("Not implemented or Error hapens");
			}
		}

		static char temp2[MAX_NUM_stdio];
		char* stt=temp2;
		switch (*(fmt++)){
			case 's':
				s=va_arg(ap,char *);
				for(char *ss=s;*ss;++ss,++stt) *stt=*ss;
				break;
			case 'd':
				cao_arg(d,ap,length)
				stt=num_to_str(stt,d,flags&positive);
				break;
			case 'c':
				c=(char)va_arg(ap,int);
				*stt++=c;
				break;
			case '%':
				*stt++='%';
				break;
			case 'u':
				cao_arg(d,ap,length)
				stt=unum_to_str(stt,(unsigned)d,10);
				break;
			case 'o':
				cao_arg(d,ap,length)
				stt=unum_to_str(stt,(unsigned)d,8);
				break;
			case 'X': case 'x':case 'p':
				cao_arg(d,ap,length)
				stt=unum_to_str(stt,(unsigned)d,16);
				break;
			default:
				panic("Not implemented or error happens");
				break;
		}
		*stt='\0';

		if(!(flags&left))
			for(int i=0;i+strlen(temp2)<width;++i) *(st++)=(flags&zero?'0':' ');
		strcpy(st,temp2);
		st+=strlen(temp2);
		if(flags&left)
			for(int i=0;i+strlen(temp2)<width;++i) *(st++)=' ';
	}
	*st='\0';
	return st-out;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap; va_start(ap,fmt);
	return vsprintf(out,fmt,ap);
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list ap; va_start(ap,fmt);
	return vsnprintf(out,n,fmt,ap);
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  int len=vsprintf(temp,fmt,ap);
	strncpy(out,temp,n-1);
	out[n-1]='\0';
	return len;
}

#endif
