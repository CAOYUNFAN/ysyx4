#include <NDL.h>
#include <SDL.h>
#include <string.h>
#include <assert.h>

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

static char buf[32];
static uint8_t keys_status[SDLK_TOTAL];
static inline void deal_event(SDL_Event *event){
//  printf("%s %s ",buf,buf+3);
  if(buf[1]=='d') event->type=SDL_KEYDOWN;else event->type=SDL_KEYUP;
  for(int i=1;i<sizeof(keyname)/sizeof(char *);++i) 
  if(strcmp(buf+3,keyname[i])==0){
    event->key.keysym.sym=i;
    keys_status[i]=1-event->type;
//    printf("%d\n",i);
    break;
  }
  return;
}

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
//  printf("EVENT==NULL:%d\n",ev==NULL?1:0);
  if(ev==NULL) return 1;
  if(!NDL_PollEvent(buf,100)) return /*printf("Nothing!\n"),*/0;
  deal_event(ev);
  return 1;
}

int SDL_WaitEvent(SDL_Event *event) {
  assert(event);
  while(!SDL_PollEvent(event));
  return 1;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  return &keys_status[0];
}
