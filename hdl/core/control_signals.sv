package control_signals;
	typedef enum {
		SEL_REG_IN_IR_IMM,
		SEL_REG_IN_VRAM_OUT,
		SEL_REG_IN_ALU_OUT
	} sel_reg_in_t;

	typedef enum {
		SEL_REG_ADDR_IR_SR,
		SEL_REG_ADDR_IR_DR
	} sel_reg_addr_t;

	typedef enum {
		SEL_ALU_IN1_SR1OUT,
		SEL_ALU_IN1_PC
	} sel_alu_in1_t;

	typedef enum {
		SEL_ALU_IN2_SR2OUT,
		SEL_ALU_IN2_IR_IMM,
		SEL_ALU_IN2_SIMM4,
		SEL_ALU_IN2_SIMM8
	} sel_alu_in2_t;

	typedef enum {
		SEL_PC_ADDER_IN_ONE,
		SEL_PC_ADDER_IN_IR_IMM
	} sel_pc_adder_t;

	typedef enum {
		SEL_PC_IN_ADDER,
		SEL_PC_IN_SR1OUT
	} sel_pc_in_t;

	typedef enum {
		SEL_VRAM_ADDR_SR1OUT,
		SEL_VRAM_ADDR_SR2OUT
	} sel_vram_addr_t;

	typedef struct {
		logic ld_ir;

		// PC
		logic ld_pc;
		sel_pc_adder_t sel_pc_adder;
		sel_pc_in_t sel_pc_in;

		// Register file
		logic reg_w;
		sel_reg_in_t sel_reg_in;
		sel_reg_addr_t sel_sr1addr;
		sel_reg_addr_t sel_sr2addr;

		// ALU
		sel_alu_in1_t sel_alu_in1;
		sel_alu_in2_t sel_alu_in2;

		// ROM
		logic rom_active;

		// VRAM
		logic vram_active;
		logic vram_w;
		sel_vram_addr_t sel_vram_addr;

		logic ld_flags;
	} ctrl_t;

	typedef struct packed {
		logic n, z, c;
	} flags_t;

	typedef enum logic [3:0] {
		s_reset,
		s_fetch, // decode is lumped into fetch
		s_alu,
		s_sh,
		s_ld,
		s_st,
		s_ldi,
		s_b,
		s_addi,
		s_aipc,

		s_ill
	} ctrl_state_t;
endpackage
