import opcode::*;
import control_signals::*;

module control (
	input clk, rst,

	input ir_word_t ir,
	input ir_word_t rom_out,
	input flags_t flags,

	input rom_ready,
	input vram_ready,

	output ctrl_t ctrl
);
	localparam ctrl_t CTRL_DEFAULT = '{
		ld_ir : 1'b0,
		ld_pc : 1'b0,
		sel_pc_adder : SEL_PC_ADDER_IN_ONE,
		sel_pc_in : SEL_PC_IN_ADDER,
		reg_w : 1'b0,
		sel_reg_in : SEL_REG_IN_ALU_OUT,
		sel_sr1addr : SEL_REG_ADDR_IR_SR,
		sel_sr2addr : SEL_REG_ADDR_IR_SR,
		sel_alu_in1 : SEL_ALU_IN1_SR1OUT,
		sel_alu_in2 : SEL_ALU_IN2_SR2OUT,
		rom_active : 1'b0,
		vram_active : 1'b0,
		vram_w : 1'b0,
		sel_vram_addr : SEL_VRAM_ADDR_SR1OUT,
		ld_flags : 1'b0
	};

	logic brc; // branch condition
	ctrl_state_t state, next_state;

	assign brc = (flags.n & ir[IR_BR_N_BIT])
	             | (flags.z & ir[IR_BR_Z_BIT])
	             | (flags.c & ir[IR_BR_C_BIT])
	             | (ir[IR_BR_N_BIT] & ir[IR_BR_Z_BIT] & ir[IR_BR_C_BIT]);

	always_comb begin
		ctrl = CTRL_DEFAULT;
		next_state = state;

		case (state)
		s_reset : next_state = s_fetch;
		s_fetch : begin
			ctrl.rom_active = 1'b1;
			if (~rom_ready) next_state = s_fetch;
			else begin
				ctrl.ld_ir = 1'b1;

				ctrl.rom_active = 1'b0;
				ctrl.sel_pc_adder = SEL_PC_ADDER_IN_ONE;
				ctrl.sel_pc_in = SEL_PC_IN_ADDER;
				ctrl.ld_pc = 1'b1;

				case (rom_out[IR_OPCODE_RANGE_HI:IR_OPCODE_RANGE_LO])
				OP_ADD,
				OP_SUB,
				OP_MUL,
				OP_AND,
				OP_OR,
				OP_XOR,
				OP_NOT  : next_state = s_alu;
				OP_SH   : next_state = s_sh;
				OP_LD   : next_state = s_ld;
				OP_ST   : next_state = s_st;
				OP_LDI  : next_state = s_ldi;
				OP_B    : next_state = s_b;
				OP_ADDI : next_state = s_addi;
				OP_AIPC : next_state = s_aipc;
				default: next_state = s_ill;
				endcase
			end
		end
		s_alu : begin
			// dr <- ALU_OP(sr1, sr2)
			// set flags
			ctrl.reg_w = 1'b1;
			ctrl.sel_reg_in = SEL_REG_IN_ALU_OUT;
			ctrl.sel_sr1addr = SEL_REG_ADDR_IR_SR;
			ctrl.sel_sr2addr = SEL_REG_ADDR_IR_SR;
			ctrl.sel_alu_in1 = SEL_ALU_IN1_SR1OUT;
			ctrl.sel_alu_in2 = SEL_ALU_IN2_SR2OUT;
			ctrl.ld_flags = 1'b1;
			next_state = s_fetch;
		end
		s_sh : begin
			// dr <- SHIFT(dr, imm)
			// set flags
			ctrl.reg_w = 1'b1;
			ctrl.sel_reg_in = SEL_REG_IN_ALU_OUT;
			ctrl.sel_sr1addr = SEL_REG_ADDR_IR_DR;
			ctrl.sel_alu_in1 = SEL_ALU_IN1_SR1OUT;
			ctrl.sel_alu_in2 = SEL_ALU_IN2_IR_IMM;
			ctrl.ld_flags = 1'b1;
			next_state = s_fetch;
		end
		s_ld : begin
			// vram_addr = sr1
			ctrl.sel_reg_in = SEL_REG_IN_VRAM_OUT;
			ctrl.sel_sr1addr = SEL_REG_ADDR_IR_SR;
			if (~vram_ready) ctrl.vram_active = 1'b1;
			ctrl.sel_vram_addr = SEL_VRAM_ADDR_SR1OUT;
			if (vram_ready) begin
				ctrl.reg_w = 1'b1;
				next_state = s_fetch;
			end
			else next_state = s_ld;
		end
		s_st : begin
			// vram_addr = dr
			// vram_in = sr1
			ctrl.sel_sr1addr = SEL_REG_ADDR_IR_SR;
			ctrl.sel_sr2addr = SEL_REG_ADDR_IR_DR;
			if (~vram_ready) begin
				ctrl.vram_active = 1'b1;
				ctrl.vram_w = 1'b1;
			end
			ctrl.sel_vram_addr = SEL_VRAM_ADDR_SR2OUT;
			if (vram_ready) next_state = s_fetch;
			else next_state = s_st;
		end
		s_ldi : begin
			// dr <- ZEXT(IR[7:0])
			ctrl.reg_w = 1'b1;
			ctrl.sel_reg_in = SEL_REG_IN_IR_IMM;
			next_state = s_fetch;
		end
		s_b : begin
			if (brc) begin
				ctrl.ld_pc = 1'b1;
				if (ir[IR_BR_I_BIT]) begin
					ctrl.sel_pc_adder = SEL_PC_ADDER_IN_IR_IMM;
					ctrl.sel_pc_in = SEL_PC_IN_ADDER;
				end else begin
					ctrl.sel_pc_in = SEL_PC_IN_SR1OUT;
					ctrl.sel_sr1addr = SEL_REG_ADDR_IR_SR;
				end
			end
			next_state = s_fetch;
		end
		s_addi : begin
			// dr <- dr + SEXT(IR[7:0])
			ctrl.reg_w = 1'b1;
			ctrl.sel_reg_in = SEL_REG_IN_ALU_OUT;
			ctrl.sel_sr1addr = SEL_REG_ADDR_IR_SR;
			ctrl.sel_alu_in1 = SEL_ALU_IN1_SR1OUT;
			ctrl.sel_alu_in2 = SEL_ALU_IN2_SIMM4;
			ctrl.ld_flags = 1'b1;
			next_state = s_fetch;
		end
		s_aipc : begin
			// dr <- PC + SEXT(IR[7:0])
			ctrl.reg_w = 1'b1;
			ctrl.sel_reg_in = SEL_REG_IN_ALU_OUT;
			ctrl.sel_alu_in1 = SEL_ALU_IN1_PC;
			ctrl.sel_alu_in2 = SEL_ALU_IN2_SIMM8;
			ctrl.ld_flags = 1'b1;
			next_state = s_fetch;
		end
		default : next_state = s_ill;
		endcase
	end

	always_ff @(posedge clk) begin
		if (rst) state <= s_reset;
		else state <= next_state;
	end
endmodule
