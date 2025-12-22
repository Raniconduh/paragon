import attrs::*;

module reg_file_tb();
	core_id_t core_id = 3;

	logic clk, rst;

	reg_addr_t sr1addr, sr2addr, dr_addr;	
	core_word_t d_in, sr1out, sr2out;
	logic w;

	reg_file reg_file_inst (
		.clk(clk),
		.rst(rst),
		.sr1addr(sr1addr),
		.sr2addr(sr2addr),
		.dr_addr(dr_addr),
		.d_in(d_in),
		.w(w),
		.sr1out(sr1out),
		.sr2out(sr2out),

		.core_id(core_id)
	);

	initial clk = 1'b1;
	always #5 clk = ~clk;

	initial begin
		rst = 1'b1;
		w = 1'b0;
		repeat (2) @(posedge clk);
		rst = 1'b0;

		// test reset
		for (int i = 0; i < N_REGS - 1; i++) begin
			@(posedge clk);

			sr1addr = i;
			sr2addr = i;
			#1;
			assert ((sr1out == sr2out) && (sr2out == 0)) else $error("Reset failed");
		end

		@(posedge clk);

		// write to each register
		for (int i = 1; i < N_REGS - 1; i++) begin
			@(posedge clk);
			dr_addr = i;
			d_in = $urandom();
			w = 1;

			@(posedge clk);
			w = 0;
			sr1addr = i;
			sr2addr = i;
			#1;
			assert ((sr1out == sr2out) && (sr2out == d_in)) else $error("Write or readback failed");
		end

		// write to zero register
		repeat (10) begin
			@(posedge clk);
			dr_addr = 0;
			d_in = $urandom();
			w = 1;

			@(posedge clk);
			w = 0;
			sr1addr = 0;
			#1;
			assert (sr1out == 0) else $error("Write to zero register invalid");
		end

		// ensure sr1out and sr2out are separate
		repeat (10) begin
			core_word_t a, b;
			a = $urandom();
			b = $urandom();

			@(posedge clk);
			dr_addr = 3;
			d_in = a;
			w = 1;
			@(posedge clk);
			dr_addr = 14;
			d_in = b;
			w = 1;
			@(posedge clk);
			w = 0;
			sr1addr = 3;
			sr2addr = 14;
			#1;
			assert ((sr1out == a) && (sr2out == b)) else $error("sr1, sr2 outputs invalid");
		end

		// test core ID
		repeat (5) begin
			@(posedge clk);
			dr_addr = 15;
			d_in = $urandom();
			w = 1;
			@(posedge clk);
			w = 0;
			sr1addr = 15;
			#1;
			assert (sr1out == core_id) else $error("Invalid write to core ID");
		end

		$finish();
	end
endmodule
