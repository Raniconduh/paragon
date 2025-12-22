import attrs::*;
import cache_attrs::*;

// private core L1 video cache
module l1cache (
	input logic clk, rst,

	// core interface
	input logic en, w,
	input vram_addr_t addr,
	input vram_word_t d_in,
	output vram_word_t d_out,
	output logic ready,

	// L2 interface
	output logic l2_en, l2_w,
	output fb_addr_t l2_addr,
	output fb_word_t l2_in,
	input fb_word_t l2_out,
	input logic l2_ready,
	// L2 invalidation handshacking signals
	input logic invalidate,
	input fb_addr_t inv_addr,
	output logic invalidated,

	input vram_word_t sw_in
);

l1_off_t a_offset;
l1_idx_t a_index;
l1_tag_t a_tag;
assign a_offset = addr[L1ADDROFF_HI:L1ADDROFF_LO];
assign a_index  = addr[L1ADDRIDX_HI:L1ADDRIDX_LO];
assign a_tag    = addr[L1ADDRTAG_HI:L1ADDRTAG_LO];

l1_idx_t inv_index;
l1_tag_t inv_tag;
assign inv_index = inv_addr[L1FBADDRIDX_HI:L1FBADDRIDX_LO];
assign inv_tag   = inv_addr[L1FBADDRTAG_HI:L1FBADDRTAG_LO];

// cache is only written on reads from L2
logic cache_en, cache_w;
logic cache_ready;
fb_word_t cache_out;
logic hit;
logic invhit; // invalidated line is present in the cache
fb_word_t wbuf; // write buffer

assign l2_in = wbuf;
assign l2_addr = {a_tag, a_index};

logic valid[L1_DEPTH];
l1_tag_t tags[L1_DEPTH];

assign hit = valid[a_index] && (tags[a_index] == a_tag);
assign invhit = valid[inv_index]&& (tags[inv_index] == inv_tag);

vram_word_t cache_byte;
assign cache_byte = cache_out[a_offset*8 +: 8];

sp_bram #(
	.WIDTH(L1_WIDTH),
	.DEPTH(L1_DEPTH)
) l1_bram (
	.clk(clk),
	.ena(cache_en),
	.wa(cache_w),
	.addra(a_index),
	.d_ina(wbuf),
	.d_outa(cache_out),
	.readya(cache_ready)
);


logic set_invalid;
logic set_valid;
logic latch_cache_out;
fb_word_t r_cache_out;

typedef enum logic [2:0] {
	s_reset,
	s_idle,
	s_wait_read,
	s_wait_write,
	s_wait_write_l2,
	s_refill,
	s_switches
} state_t;
state_t state, next_state;

always_ff @(posedge clk) begin
	if (rst) begin
		state <= s_reset;

		for (int i = 0; i < L1_DEPTH; i++) begin
			valid[i] <= 1'b0;
		end
	end else begin
		state <= next_state;

		if (set_invalid) begin
			valid[inv_index] <= 1'b0;
		end else if (set_valid) begin
			valid[a_index] <= 1'b1;
			tags[a_index] <= a_tag;
		end

		if (latch_cache_out) begin
			r_cache_out <= cache_out;
		end
	end
end
always_comb begin
	next_state = state;

	set_valid = 1'b0;
	cache_en = 1'b0;
	cache_w = 1'b0;
	ready = 1'b0;

	l2_en = 1'b0;
	l2_w = 1'b0;

	latch_cache_out = 1'b0;

	wbuf = cache_out;
	d_out = cache_byte;

	case (state)
		s_reset : next_state = s_idle;

		s_idle : begin
			if (en) begin
				// pull value from on board switches
				if (addr == '1) begin
					d_out = sw_in;
					next_state = s_switches;
				// this address is in the cache actually
				end else if (hit) begin
					cache_en = 1'b1;
					if (!w) next_state = s_wait_read;
					else next_state = s_wait_write;
				end else begin
					// if it is a read or a write, the line needs to be
					// fetched from L2. Overwrite the current line in the
					// cache with the line from L2 once it is fetched
					l2_en = 1'b1;
					wbuf = l2_out;
					next_state = s_refill;
				end
			end
		end

		s_wait_read : begin
			if (!hit) next_state = s_idle;
			else begin
				cache_en = 1'b1;
				if (cache_ready) begin
					cache_en = 1'b0;
					ready = 1'b1;
					next_state = s_idle;
				end
			end
		end

		s_wait_write : begin
			if (!hit) next_state = s_idle;
			else begin
				cache_en = 1'b1;
				if (cache_ready) begin
					cache_en = 1'b0;
					latch_cache_out = 1'b1;
					next_state = s_wait_write_l2;
				end
			end
		end

		s_wait_write_l2 : begin
			if (!hit) next_state = s_idle;
			else begin
				cache_en = 1'b1;
				cache_w = 1'b1;

				wbuf = r_cache_out;
				wbuf[a_offset*8 +: 8] = d_in;

				l2_en = 1'b1;
				l2_w = 1'b1;
				if (l2_ready) begin
					l2_en = 1'b0;
					ready = 1'b1;
					next_state = s_idle;
				end
			end
		end

		s_refill : begin
			l2_en = 1'b1;
			wbuf = l2_out;

			if (l2_ready) begin
				l2_en = 1'b0;
				cache_en = 1'b1;
				cache_w = 1'b1;
				set_valid = 1'b1;
				// idle will complete the transaction now that the requested
				// cache line has been stores
				next_state = s_idle;
			end
		end

		s_switches : begin
			d_out = sw_in;
			ready = 1'b1;
			next_state = s_idle;
		end

		default : next_state = s_reset;
	endcase
end

always_comb begin
	set_invalid = 1'b0;
	invalidated = 1'b0;
	if (invalidate) begin
		if (invhit) set_invalid = 1'b1;
		invalidated = 1'b1;
	end
end

endmodule
