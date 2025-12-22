#pragma once

enum opcode_t {
	OP_ADD  = 0b0000,
	OP_SUB  = 0b0001,
	OP_MUL  = 0b0010,
	OP_AND  = 0b0011,
	OP_OR   = 0b0100,
	OP_XOR  = 0b0101,
	OP_NOT  = 0b0110,
	OP_SH   = 0b0111,
	OP_LD   = 0b1000,
	OP_ST   = 0b1001,
	OP_LDI  = 0b1010,
	OP_B    = 0b1011,
	OP_ADDI = 0b1100,
	OP_AIPC = 0b1101,
};

#define GET_OP(word)    (((word) >> 12) & 0b1111)
#define GET_DR(word)    (((word) >> 8)  & 0b1111)
#define GET_SR1(word)   (((word) >> 4)  & 0b1111)
#define GET_SR2(word)   (((word) >> 0)  & 0b1111)
#define GET_SHL(word)   (((word) >> 7)  & 1)
#define GET_SHA(word)   (((word) >> 6)  & 1)
#define GET_SHIMM(word) (((word) >> 0)  & 0b11111)
#define GET_IMM8(word)  (((word) >> 0)  & 0b11111111)
#define GET_BN(word)    (((word) >> 11) & 1)
#define GET_BZ(word)    (((word) >> 10) & 1)
#define GET_BC(word)    (((word) >> 9)  & 1)
#define GET_BI(word)    (((word) >> 8)  & 1)
#define GET_IMM4(word)  (((word) >> 0)  & 0b1111)

#define MSB(word) (((word) >> 23) & 1)

#define MASK(x) ((x) & 0xFFFFFF)
