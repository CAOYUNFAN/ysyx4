#include <am.h>

void __am_timer_init() {
}

#define RTC_ADDR 0xa0000000+0x00000048

static inline uint64_t inq(uintptr_t addr) { return *(volatile uint64_t *)addr; }
void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = (uint64_t)inq(RTC_ADDR);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
