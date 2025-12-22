#include <iostream>
#include <cstdint>
#include <vector>

#include "vram.hpp"
#include "core.hpp"
#include "patterns.hpp"


uint32_t sext8(uint8_t imm8) {
	return MASK((int32_t)((uint32_t)imm8 << 24) >> 24);
}

uint32_t sext4(uint8_t imm4) {
	return MASK((int32_t)((uint32_t)imm4 << 28) >> 28);
}

void set_reg(core_t & core, uint8_t reg, uint32_t val) {
	if (reg != 0 && reg != 15) core.regs[reg] = MASK(val);
}

uint32_t get_reg(core_t & core, uint8_t reg) {
	if (reg == 0) return 0;
	else if (reg == 15) return core.id;
	else return core.regs[reg];
}

void step_core(core_t & core, const std::vector<uint32_t> & kernel) {
	uint32_t & pc = core.pc;
	flags_t & flags = core.flags;

	uint32_t ir = kernel[pc];
	pc++;

	uint8_t dra = GET_DR(ir);
	uint32_t dr = get_reg(core, dra);
	uint32_t sr1  = get_reg(core, GET_SR1(ir));
	uint32_t sr2  = get_reg(core, GET_SR2(ir));

	uint8_t shimm = GET_SHIMM(ir);
	uint8_t imm8  = GET_IMM8(ir);
	uint8_t imm4  = GET_IMM4(ir);

	bool branch = (GET_BN(ir) & flags.n)
                | (GET_BZ(ir) & flags.z)
	            | (GET_BC(ir) & flags.c)
	            | (GET_BN(ir) & GET_BZ(ir) & GET_BC(ir));

	uint32_t op;
	switch (GET_OP(ir)) {
		case OP_ADD: op = sr1 + sr2; break;
		case OP_SUB: op = sr1 - sr2; break;
		case OP_MUL: op = sr1 * sr2; break;
		case OP_AND: op = sr1 & sr2; break;
		case OP_OR:  op = sr1 | sr2; break;
		case OP_XOR: op = sr1 ^ sr2; break;
		case OP_NOT: op = ~sr1; break;
		case OP_SH:
			if (GET_SHL(ir)) op = dr << shimm;
			else if (GET_SHA(ir)) op = ((int32_t)(dr << 8) >> shimm) >> 8;
			else op = dr >> shimm;
			break;
		case OP_LD:  set_reg(core, dra, (uint32_t)vram_get(sr1)); break;
		case OP_ST:  vram_set(dr, sr1); break;
		case OP_LDI: set_reg(core, dra, (uint32_t)imm8); break;
		case OP_B:
			if (branch) {
				if (GET_BI(ir)) pc = PC_MASK(pc + sext8(imm8));
				else pc = PC_MASK(sr1);
			}
			break;
		case OP_ADDI: op = sr1 + sext4(imm4); break;
		case OP_AIPC: op = pc + sext8(imm8); break;
		default: core.halted = true; break;
	}

	switch (GET_OP(ir)) {
		case OP_ADD:
		case OP_SUB:
		case OP_ADDI:
		case OP_AIPC:
		case OP_MUL:
		case OP_AND:
		case OP_OR:
		case OP_XOR:
		case OP_NOT:
		case OP_SH:
			flags.n = MSB(op);
			flags.z = (op == 0);
			flags.c = (op >> 24) & 1;
			set_reg(core, dra, op);
			break;
		default: break;
	}
}
