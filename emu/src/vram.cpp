#include <cstdint>

#include "framebuffer.h"
#include "vram.hpp"

extern uint8_t framebuffer[FB_DEPTH];
static uint8_t vram[VRAM_DEPTH];

uint8_t vram_get(uint32_t addr) {
	addr &= ADDR_MASK;
	if (addr < FB_DEPTH) return framebuffer[addr];
	else return vram[addr];
}

void vram_set(uint32_t addr, uint8_t val) {
	addr &= ADDR_MASK;
	if (addr < FB_DEPTH) framebuffer[addr] = val;
	else vram[addr] = val;
}
