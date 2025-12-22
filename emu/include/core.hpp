#pragma once

#include <cstdint>
#include <vector>

#define N_REGS 16

#define PC_MASK(x) ((x) & 0b11111111111)

typedef struct {
	bool n, z, c;
} flags_t;

typedef struct {
	uint32_t pc;

	uint32_t regs[N_REGS];
	flags_t flags;

	uint8_t id;
	bool halted;
} core_t;

void step_core(core_t & core, const std::vector<uint32_t> & kernel);
