import attrs::*;
import control_signals::*;
import opcode::*;

module core_tb();
	logic clk, rst;
	core_id_t core_id;
	ir_word_t rom_out;
	logic rom_ready, rom_active;
	rom_addr_t rom_addr;

	vram_word_t vram_out, vram_in;
	logic vram_ready, vram_active, vram_w;
	vram_addr_t vram_addr;

	datapath datapath_inst (
		.clk(clk),
		.rst(rst),
		.core_id(core_id),
		.rom_out(rom_out),
		.rom_ready(rom_ready),
		.rom_addr(rom_addr),
		.rom_active(rom_active),
		.vram_out(vram_out),
		.vram_in(vram_in),
		.vram_ready(vram_ready),
		.vram_addr(vram_addr),
		.vram_active(vram_active),
		.vram_w(vram_w)
	);

	initial clk = 1'b1;
	always #5 clk = ~clk;

	ctrl_state_t state;
	assign state = datapath_inst.core_control.state;
	flags_t flags;
	assign flags = datapath_inst.flags;
	core_word_t r1, r2, r3, r4;
	assign r1 = datapath_inst.core_reg_file.regs[1];
	assign r2 = datapath_inst.core_reg_file.regs[2];
	assign r3 = datapath_inst.core_reg_file.regs[3];
	assign r4 = datapath_inst.core_reg_file.regs[4];
	rom_addr_t pc;
	assign pc = datapath_inst.pc;

	ir_word_t ir;
	assign ir = datapath_inst.core_control.ir;

	initial begin
		rom_ready = 1'b0;
		vram_ready = 1'b0;

		rst = 1'b1;
		@(posedge clk);
		#0;
		assert (state == s_reset) else $error("FSM not in s_reset on reset");
		rst = 1'b0;

		// LDI R1, 5
		wait (state == s_fetch);
		#1;
		wait (rom_active);
		#1;
		rom_out = 16'b1010000100000101;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;

		wait (state == s_ldi);
		#1;
		@(posedge clk);
		#1;
		assert (datapath_inst.core_reg_file.regs[1] == 24'd5) else $error("LDI did not store to register correctly");


		// LDI R2, 11
		wait ((state == s_fetch) && rom_active);
		#1;
		rom_out = 16'b1010001000001011;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		wait (state == s_ldi);
		#1;
		@(posedge clk);
		#1;
		assert (datapath_inst.core_reg_file.regs[2] == 24'd11) else $error("LDI 2 did not store to register correctly");

		// MUL R3, R1, R2
		wait ((state == s_fetch) && rom_active);
		#1;
		rom_out = 16'b0010001100010010;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		wait (state == s_alu);
		#1;
		@(posedge clk);
		#1;
		assert (datapath_inst.core_reg_file.regs[3] == 24'd55) else $error("MUL not written to register correctly");

		// SH.L R3, 9
		wait ((state == s_fetch) && rom_active);
		#1;
		rom_out = 16'b0111001110001001;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		wait (state == s_sh);
		#1;
		@(posedge clk);
		#1;
		assert (datapath_inst.core_reg_file.regs[3] == (24'd55 << 9)) else $error("SHL failed");

		// SH.R R3, 5
		wait ((state == s_fetch) && rom_active);
		#1;
		rom_out = 16'b0111001100000101;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		wait (state == s_sh);
		#1;
		@(posedge clk);
		#1;
		assert (datapath_inst.core_reg_file.regs[3] == (24'd55 << 4)) else $error("SHR failed");

		// B.NZC -5
		wait ((state == s_fetch) && rom_active);
		#1;
		rom_out = 16'b1011111111111011;
		rom_ready = 1'b1;
		@(posedge clk);
		wait (state == s_b);
		#1;
		@(posedge clk);
		#1;
		assert (state == s_fetch) else $error("Did not transition to fetch after B");
		assert (rom_addr == 19'd1) else $error("Incorrect PC after B: want %0d, have %0d", 1, rom_addr);

		// B.NZC R3
		rom_out = 16'b1011111000110000;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		#1;
		@(posedge clk);
		#1;
		assert (state == s_fetch) else $error("Did not transition to fetch after B");
		assert (rom_addr == (19'd55<<4)) else $error("Incorrect PC after B: want %0d, have %0d", (55<<4), rom_addr);

		// SUB R0, R0, R1
		rom_out = 16'b0001000000000001;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		#1;
		@(posedge clk);
		#1;
		assert ((flags.n == 1'b1) && (flags.z == 0) && (flags.c == 0)) else $error("Flags not set correctly");

		// BR.z R2
		rom_out = 16'b1011010000100000;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		#1;
		@(posedge clk);
		#1;
		assert (rom_addr != 19'd11) else $error("Branched when flags were not requisite");

		// BR.n R2
		rom_out = 16'b1011100000100000;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		#1;
		@(posedge clk);
		#1;
		assert (rom_addr == 19'd11) else $error("Did not branch when flags were requisite");

		// ADD R3, R3, R3
		wait ((state == s_fetch) && rom_active);
		repeat (2) @(posedge clk);
		#1;
		assert (state == s_fetch) else $error("Prematurely left fetch");
		rom_out = 16'b0000001100110011;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		#1;
		assert (state == s_alu) else $error("Did not transition correctly");
		@(posedge clk);
		#1;
		assert (datapath_inst.core_reg_file.regs[3] == (24'd55 << 5)) else $error("ADD after long wait failed");

		// LD R4, R3
		wait ((state == s_fetch) && rom_active);
		#1;
		rom_out = 16'b1000010000110000;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		#1;
		assert (state == s_ld) else $error("Did not transition to LD");
		assert ((vram_active == 1'b1) && (vram_w == 1'b0)) else $error("VRAM signals incorrectly set for LD");
		assert (vram_addr == 19'd55 << 5) else $error("VRAM addr incorrect");
		vram_out = 8'hbf;
		vram_ready = 1'b1;
		@(posedge clk);
		vram_ready = 1'b0;
		@(posedge clk);
		#1;
		assert (state == s_fetch) else $error("Not in fetch after LD");
		assert (datapath_inst.core_reg_file.regs[4] == 8'hbf) else $error("LD failed");

		// LD R4, R3
		wait ((state == s_fetch) && rom_active);
		#1;
		// rom out same as before
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		repeat (4) @(posedge clk);
		vram_out = 8'h67;
		vram_ready = 1'b1;
		@(posedge clk);
		vram_ready = 1'b0;
		@(posedge clk);
		#1;
		assert (datapath_inst.core_reg_file.regs[4] == 8'h67) else $error("Long wait LD failed");

		// ST R4, R1
		wait ((state == s_fetch) && rom_active);
		#1;
		rom_out = 16'b1001010000010000;
		rom_ready = 1'b1;
		@(posedge clk);
		rom_ready = 1'b0;
		#1;
		assert (state == s_st) else $error("Did not transition to ST");
		assert ((vram_active == 1'b1) && vram_w == 1'b1) else $error("VRAM signals incorrectly set for ST");
		assert (vram_addr == 19'h67) else $error("VRAM addr incorrect");
		assert (vram_in == 8'd5) else $error("VRAM input incorrect");
		repeat (4) @(posedge clk);
		vram_ready = 1'b1;
		@(posedge clk);
		vram_ready = 1'b0;
		#1;
		assert (state == s_fetch) else $error("Did not transition out of ST");

		@(posedge clk);
		$finish();
	end
endmodule
