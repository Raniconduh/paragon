import attrs::*;

module reg_file (
	input logic clk, rst,

	input reg_addr_t sr1addr, sr2addr,
	input reg_addr_t dr_addr,
	input core_word_t d_in,
	input logic w,

	input core_id_t core_id,

	output core_word_t sr1out, sr2out
);
	// register 0 is the zero register
	// register 15 is the core ID register
	core_word_t regs [1:N_REGS-1];

	always_ff @(posedge clk) begin
		if (rst) for (int i = 1; i < N_REGS - 1; i++) regs[i] <= 0;
		else if (w && (dr_addr != 0) && (dr_addr != N_REGS - 1)) regs[dr_addr] <= d_in;
	end

	always_comb begin
		case (sr1addr)
			4'b0000 : sr1out = 0;
			4'b1111 : sr1out = core_id;
			default : sr1out = regs[sr1addr];
		endcase

		case (sr2addr)
			4'b0000 : sr2out = 0;
			4'b1111 : sr2out = core_id;
			default : sr2out = regs[sr2addr];
		endcase
	end
endmodule
