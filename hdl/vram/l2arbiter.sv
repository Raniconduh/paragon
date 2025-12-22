import attrs::*;

// round robin arbiter for requests to L2
module l2arbiter (
	input logic clk, rst,

	input logic busy,
	input logic reqs[N_CORES],
	output core_id_t grant,
	output logic grant_ready
);

core_id_t ptr;
core_id_t next_ptr;
core_id_t idx;
logic load_grant;
core_id_t next_grant;

typedef enum logic [1:0] {
	s_idle,
	s_ready,
	s_wait_busy,
	s_wait_free
} state_t;
state_t state, next_state;

always_ff @(posedge clk) begin
	if (rst) begin
		ptr <= 0;
		state <= s_idle;
		grant <= 0;
	end else begin
		ptr <= next_ptr;
		state <= next_state;
		grant <= next_grant;
	end
end
always_comb begin
	next_ptr = ptr;
	next_state = state;
	next_grant = grant;
	idx = ptr;

    grant_ready = 1'b0;
	load_grant = 1'b0;

	case (state)
		s_idle : begin
			if (!busy) for (int i = 0; i < N_CORES; i++) begin
				idx = (ptr + i) % N_CORES;
				if (reqs[idx]) begin
					next_grant = idx;
					next_ptr = (idx + 1) % N_CORES;
					next_state = s_ready;
					break;
				end
			end
		end

		s_ready : begin
			grant_ready = 1'b1;
			if (!busy) next_state = s_wait_busy;
			else next_state = s_wait_free;
		end

		s_wait_busy : begin
			if (busy) next_state = s_wait_free;
		end

		s_wait_free : begin
			if (!busy) next_state = s_idle;
		end

		default : next_state = s_idle;
	endcase
end
endmodule
