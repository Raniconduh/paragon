import attrs::*;
import control_signals::*;
import opcode::*;

// interconnect module
// exposes signals for tertiary modules (program ROM, etc)
module datapath (
	input logic clk, rst,
	input core_id_t core_id,

	input ir_word_t rom_out,
	input logic rom_ready,
	output rom_addr_t rom_addr,
	output logic rom_active,

	input vram_word_t vram_out,
	input logic vram_ready,
	output vram_addr_t vram_addr,
	output vram_word_t vram_in,
	output logic vram_active,
	output logic vram_w
);
	ir_word_t ir;

	rom_addr_t pc;
	rom_addr_t pc_in;
	rom_addr_t pc_adder_in2;
	rom_addr_t pc_adder_out;

	flags_t flags;

	// register file signals
	reg_addr_t sr1addr, sr2addr;
	core_word_t reg_d_in;
	core_word_t sr1out, sr2out;

	// alu signals
	core_word_t alu_in1;
	core_word_t alu_in2;
	logic carryout;
	core_word_t alu_out;

	ctrl_t ctrl;

	// instantiate modules
	register #(
		.WIDTH(IR_WIDTH)
	) core_ir (
		.clk(clk),
		.rst(rst),
		.w(ctrl.ld_ir),
		.d(rom_out),
		.q(ir)
	);

	register #(
		.WIDTH(ROM_ADDR_WIDTH)
	) core_pc (
		.clk(clk),
		.rst(rst),
		.w(ctrl.ld_pc),
		.d(pc_in),
		.q(pc)
	);

	reg_file core_reg_file (
		.clk(clk),
		.rst(rst),
		.sr1addr(sr1addr),
		.sr2addr(sr2addr),
		.dr_addr(ir[IR_DR_RANGE_HI:IR_DR_RANGE_LO]),
		.d_in(reg_d_in),
		.w(ctrl.reg_w),
		.core_id(core_id),
		.sr1out(sr1out),
		.sr2out(sr2out)
	);

	alu core_alu (
		.d_in1(alu_in1),
		.d_in2(alu_in2),
		.op(opcode_t'(ir[IR_OPCODE_RANGE_HI:IR_OPCODE_RANGE_LO])),
		.shl(ir[IR_SHL_BIT]),
		.sha(ir[IR_SHA_BIT]),
		.carryout(carryout),
		.d_out(alu_out)
	);

	control core_control (
		.clk(clk),
		.rst(rst),
		.ir(ir),
		.rom_out(rom_out),
		.flags(flags),
		.rom_ready(rom_ready),
		.vram_ready(vram_ready),
		.ctrl(ctrl)
	);

	always_ff @(posedge clk) begin
		if (ctrl.ld_flags) begin
			flags.n <= alu_out[$high(alu_out)];
			flags.z <= ~|alu_out;
			flags.c <= carryout;
		end
	end

	// wire networks
	assign rom_addr = pc;
	assign rom_active = ctrl.rom_active;
	assign vram_active = ctrl.vram_active;
	assign vram_w = ctrl.vram_w;
	assign vram_in = sr1out;

	assign pc_adder_out = pc + pc_adder_in2;

	// multiplexers
	always_comb begin
		case (ctrl.sel_pc_adder)
			SEL_PC_ADDER_IN_ONE    : pc_adder_in2 = 1;
			SEL_PC_ADDER_IN_IR_IMM : pc_adder_in2 = {{3{ir[IR_SIMM8_RANGE_HI]}}, ir[IR_SIMM8_RANGE_HI:IR_SIMM8_RANGE_LO]};
			default : pc_adder_in2 = 1;
		endcase

		case (ctrl.sel_pc_in)
			SEL_PC_IN_ADDER  : pc_in = pc_adder_out;
			SEL_PC_IN_SR1OUT : pc_in = sr1out;
			default : pc_in = pc_adder_out;
		endcase

		case (ctrl.sel_reg_in)
			SEL_REG_IN_IR_IMM   : reg_d_in = ir[IR_LDI_IMM_RANGE_HI:IR_LDI_IMM_RANGE_LO];
			SEL_REG_IN_VRAM_OUT : reg_d_in = vram_out;
			SEL_REG_IN_ALU_OUT  : reg_d_in = alu_out;
			default : reg_d_in = alu_out;
		endcase

		case (ctrl.sel_sr1addr)
			SEL_REG_ADDR_IR_SR : sr1addr = ir[IR_SR1_RANGE_HI:IR_SR1_RANGE_LO];
			SEL_REG_ADDR_IR_DR : sr1addr = ir[IR_DR_RANGE_HI:IR_DR_RANGE_LO];
			default : sr1addr = ir[IR_SR1_RANGE_HI:IR_SR1_RANGE_LO];
		endcase

		case (ctrl.sel_sr2addr)
			SEL_REG_ADDR_IR_SR : sr2addr = ir[IR_SR2_RANGE_HI:IR_SR2_RANGE_LO];
			SEL_REG_ADDR_IR_DR : sr2addr = ir[IR_DR_RANGE_HI:IR_DR_RANGE_LO];
			default : sr2addr = ir[IR_SR2_RANGE_HI:IR_SR2_RANGE_LO];
		endcase

		case (ctrl.sel_alu_in1)
			SEL_ALU_IN1_SR1OUT : alu_in1 = sr1out;
			SEL_ALU_IN1_PC     : alu_in1 = pc;
			default : alu_in1 = sr1out;
		endcase

		case (ctrl.sel_alu_in2)
			SEL_ALU_IN2_SR2OUT : alu_in2 = sr2out;
			SEL_ALU_IN2_IR_IMM : alu_in2 = ir[IR_SH_IMM_RANGE_HI:IR_SH_IMM_RANGE_LO];
			SEL_ALU_IN2_SIMM4  : alu_in2 = {{20{ir[IR_SIMM4_RANGE_HI]}}, ir[IR_SIMM4_RANGE_HI:IR_SIMM4_RANGE_LO]};
			SEL_ALU_IN2_SIMM8  : alu_in2 = {{16{ir[IR_SIMM8_RANGE_HI]}}, ir[IR_SIMM8_RANGE_HI:IR_SIMM8_RANGE_LO]};
			default : alu_in2 = sr2out;
		endcase

		case (ctrl.sel_vram_addr)
			SEL_VRAM_ADDR_SR1OUT : vram_addr = sr1out;
			SEL_VRAM_ADDR_SR2OUT : vram_addr = sr2out;
			default : vram_addr = sr1out;
		endcase
	end
endmodule
