#pragma once

#include <cstdint>

#define VRAM_DEPTH (1 << 17)
#define FB_DEPTH (320*240)

#define ADDR_MASK 0x1FFFF

uint8_t vram_get(uint32_t addr);
void vram_set(uint32_t addr, uint8_t val);
