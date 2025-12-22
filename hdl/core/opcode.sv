package opcode;
	import attrs::*;

	typedef enum logic [OPCODE_WIDTH-1:0] {
		OP_ADD  = 4'b0000,
		OP_SUB  = 4'b0001,
		OP_MUL  = 4'b0010,
		OP_AND  = 4'b0011,
		OP_OR   = 4'b0100,
		OP_XOR  = 4'b0101,
		OP_NOT  = 4'b0110,
		OP_SH   = 4'b0111,
		OP_LD   = 4'b1000,
		OP_ST   = 4'b1001,
		OP_LDI  = 4'b1010,
		OP_B    = 4'b1011,
		OP_ADDI = 4'b1100,
		OP_AIPC = 4'b1101
	} opcode_t;

	// IR Ranges:
	localparam int IR_OPCODE_RANGE_HI  = 15;
	localparam int IR_OPCODE_RANGE_LO  = 12;
//	localparam int IR_ALU_OP_RANGE_HI  = 14;
//	localparam int IR_ALU_OP_RANGE_LO  = 12;
	localparam int IR_DR_RANGE_HI      = 11;
	localparam int IR_DR_RANGE_LO      = 8;
	localparam int IR_SR1_RANGE_HI     = 7;
	localparam int IR_SR1_RANGE_LO     = 4;
	localparam int IR_SR2_RANGE_HI     = 3;
	localparam int IR_SR2_RANGE_LO     = 0;
	localparam int IR_SH_IMM_RANGE_HI  = 4;
	localparam int IR_SH_IMM_RANGE_LO  = 0;
	localparam int IR_LDI_IMM_RANGE_HI = 7;
	localparam int IR_LDI_IMM_RANGE_LO = 0;

	localparam int IR_SIMM8_RANGE_HI  = 7;
	localparam int IR_SIMM8_RANGE_LO  = 0;
	localparam int IR_SIMM4_RANGE_HI  = 3;
	localparam int IR_SIMM4_RANGE_LO  = 0;

	localparam int IR_SHL_BIT          = 7;
	localparam int IR_SHA_BIT          = 6;
	localparam int IR_BR_N_BIT         = 11;
	localparam int IR_BR_Z_BIT         = 10;
	localparam int IR_BR_C_BIT         = 9;
	localparam int IR_BR_I_BIT         = 8;

//	localparam IR_BR_SEXT_IMM(ir) = {{8{{ir}[7]}}, {ir}[7:0]};
endpackage
