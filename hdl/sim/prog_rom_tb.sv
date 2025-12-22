import attrs::*;

module prog_rom_tb();
	logic clk;

	logic prog, p_avail, p_ready, p_lo_ack, active[N_CORES], core_rst, ready[N_CORES];
	ir_word_t p_d_in, d_out[N_CORES];
	rom_addr_t addr[N_CORES];

	prog_rom prog_rom_inst (
		.clk(clk),
		.prog(prog),
		.p_avail(p_avail),
		.p_d_in(p_d_in),
		.p_ready(p_ready),
		.p_lo_ack(p_lo_ack),
		.active(active),
		.addr(addr),
		.d_out(d_out),
		.ready(ready),
		.core_rst(core_rst)
	);

	initial clk = 1'b1;
	always #5 clk = ~clk;

	ir_word_t tests[3];
	ir_word_t full_tests[ROM_DEPTH];
	logic prog_rising, prog_ff;
	assign prog_rising = prog_rom_inst.prog_rising;
	assign prog_ff = prog_rom_inst.prog_ff;

	initial begin
		prog = 0;
		p_avail = 0;
		for (int i = 0; i < N_CORES; i++) active[i] = 0;

		// test programming

		tests[0] = $urandom();
		tests[1] = $urandom();
		tests[2] = $urandom();

		repeat (2) @(posedge clk);
		#0;
		// write words to ROM
		prog = 1;
		p_d_in = tests[0];
		p_avail = 1;
		#1;
		wait (p_ready);
		p_avail = 0;
		#1;
		wait (p_lo_ack);

		assert (core_rst) else $error("Core reset is not asserted during programming");

		p_d_in = tests[1];
		p_avail = 1;
		#1;
		wait (p_ready);
		p_avail = 0;
		#1;
		wait (p_lo_ack);

		p_d_in = tests[2];
		p_avail= 1;
		#1;
		wait (p_ready);
		p_avail = 0;
		#1;
		wait(p_lo_ack);
		prog = 0;

		// read back from ROM
		for (int i = 0; i < 3; i++) begin
			@(posedge clk);
			addr[0] = i;
			active[0] = 1;
			wait (ready[0]); @(posedge clk);
			#1;
			assert (d_out[0] == tests[i]) else $error("Invalid single-core readback: want %0d, seend %0d", tests[i], d_out[0]);
			active[0] = 0;
		end

		// multicore ROM readback
		for (int core = 1; core < N_CORES; core++) begin
			for (int i = 0; i < 3; i++) begin
				@(posedge clk);
				addr[core] = i;
				active[core] = 1;
				wait (ready[core]); @(posedge clk);
				#1;
				assert (d_out[core] == tests[i]) else $error("Invalid readback from core %0d: want %0d, seen %0d", core, tests[i], d_out[core]);
				active[core] = 0;
			end
		end

		// concurrent ROM readback
		for (int i = 0; i < 3; i++) begin
			@(posedge clk);
			for (int core = 0; core < N_CORES; core++) begin
				addr[core] = i;
				active[core] = 1;
			end
			for (int core = 0; core < N_CORES; core++) begin
				wait (ready[core]);
			end
			@(posedge clk);
			#1;
			for (int core = 0; core < N_CORES; core++) begin
				assert (d_out[core] == tests[i]) else $error("Invalid parallel readback from core %0d. Want %0d, seen %0d", core, tests[i], d_out[core]);
			end
			for (int core = 0; core < N_CORES; core++) begin
				active[core] = 0;
			end
		end

		// test full rom write and readback
		for (int i = 0; i < ROM_DEPTH; i++) begin
			full_tests[i] = $urandom();
		end

		#0;
		prog = 1;
		for (int i = 0; i < ROM_DEPTH; i++) begin
			p_d_in = full_tests[i];
			p_avail = 1;
			wait (p_ready);
			p_avail = 0;
			wait (p_lo_ack);
			#0;
		end
		prog = 0;

		for (int i = 0; i < ROM_DEPTH; i++) begin
			@(posedge clk);
			#0;
			addr[0] = i;
			active[0] = 1;
			wait (ready[0]);
			@(posedge clk);
			#1;
			assert (d_out[0] == full_tests[i]) else $error("Full ROM readback failed: addr %0d, seen %0d, want %0d", i, d_out[0], full_tests[i]);
		end

		$finish();
	end
endmodule
