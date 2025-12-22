import attrs::*;
import cache_attrs::*;

module l2cache (
	input logic clk, rst,

	input logic en [N_CORES],
	input logic w [N_CORES],
	input fb_addr_t addr [N_CORES],
	input fb_word_t d_in [N_CORES],
	output fb_word_t d_out [N_CORES],
	output logic ready [N_CORES],

	output logic invalidate [N_CORES],
	output fb_addr_t inv_addr,
	input logic invalidated [N_CORES],

	output logic fb_en, fb_w,
	output fb_addr_t fb_addr,
	output fb_word_t fb_in,
	input fb_word_t fb_out,
	input logic fb_ready
);

logic cache_en;
logic cache_w;
l2_idx_t cache_addr;
fb_word_t cache_in;
fb_word_t cache_out;
logic cache_ready;

l2_idx_t a_index [N_CORES];
l2_tag_t a_tag [N_CORES];

logic busy;
core_id_t grant;
logic grant_ready;
logic latch_grant;
core_id_t r_grant;

typedef struct {
	logic valid;
	logic dirty;
	l2_tag_t tag;
} tag_t;

tag_t tags[L2_DEPTH];

l2_idx_t g_index;
l2_tag_t g_tag;
logic hit;

assign g_index = a_index[r_grant];
assign g_tag = a_tag[r_grant];
assign hit = tags[g_index].valid && (tags[g_index].tag == g_tag);

logic g_en;
logic g_w;
fb_addr_t g_addr;
fb_word_t g_in;
fb_word_t g_out;
logic g_ready;

assign g_en = en[r_grant];
assign g_w = w[r_grant];
assign g_addr = addr[r_grant];
assign g_in = d_in[r_grant];
always_comb begin
	for (int i = 0; i < N_CORES; i++) begin
		d_out[i] = 0;
		ready[i] = 0;
	end
	d_out[r_grant] = g_out;
	ready[r_grant] = g_ready;
end

genvar i;
for (i = 0; i < N_CORES; i++) begin : gen_addrs
	assign a_index[i] = addr[i][L2ADDRIDX_HI:L2ADDRIDX_LO];
	assign a_tag[i] = addr[i][L2ADDRTAG_HI:L2ADDRTAG_LO];
end

//sp_bram #(
//	.WIDTH(L2_WIDTH),
//	.DEPTH(L2_DEPTH)
//) l2_bram (
//	.clk(clk),
//	.ena(cache_en),
//	.wa(cache_w),
//	.addra(cache_addr),
//	.d_ina(cache_in),
//	.d_outa(cache_out),
//	.readya(cache_ready)
//);

l2arbiter arbiter (
	.clk(clk),
	.rst(rst),
	.busy(busy),
	.reqs(en),
	.grant(grant),
	.grant_ready(grant_ready)
);

typedef enum logic [2:0] {
	s_reset,
	s_idle,
	s_handle,
	s_wait,
	s_inv
} state_t;
state_t state, next_state;

always_ff @(posedge clk) begin
	if (rst) begin
		state <= s_reset;

		for (int i = 0; i < L2_DEPTH; i++) begin
			tags[i].valid <= 1'b0;
		end
	end else begin
		state <= next_state;

		if (latch_grant) r_grant <= grant;
	end
end
always_comb begin
    next_state = state;

	busy = 1'b1;

	fb_en = 1'b0;
	fb_w = g_w;
	fb_in = g_in;
	g_out = fb_out;
	fb_addr = g_addr;
	for (int i = 0; i < N_CORES; i++) begin
		invalidate[i] = 1'b0;
	end
	inv_addr = g_addr;
	g_ready = 1'b0;
	latch_grant = 1'b0;

	case (state)
		s_reset : next_state = s_idle;

		s_idle : begin
			busy = 1'b0;
			if (grant_ready) begin
				latch_grant = 1'b1;
				next_state = s_handle;
			end
		end

		s_handle : begin
			if (g_en) begin
				fb_en = 1'b1;
				next_state = s_wait;
			end else next_state = s_idle;
		end

		s_wait : begin
			fb_en = 1'b1;
			if (fb_ready) begin
				fb_en = 1'b0;
				g_ready = 1'b1;
				if (g_w) next_state = s_inv;
				else next_state = s_idle;
			end
		end

		s_inv : begin
			for (int i = 0; i < N_CORES; i++) begin
				invalidate[i] = 1'b1;
			end
			next_state = s_idle;
		end

		default : next_state = s_idle;
	endcase
end

endmodule
