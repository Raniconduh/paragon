#ifndef FRAMEBUFFER_H
#define FRAMEBUFFER_H

#include <stdint.h>

#define FB_WIDTH  320
#define FB_HEIGHT 240

extern uint8_t framebuffer[FB_HEIGHT*FB_WIDTH];

int fb_init(void);
void fb_setpx(uint32_t addr, uint8_t px);
void fb_refresh(void);

#endif
