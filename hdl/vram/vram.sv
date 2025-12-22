import attrs::*;

module vram (
	input logic clk, rst,

	input logic en [N_CORES],
	input logic w [N_CORES],
	input vram_addr_t addr [N_CORES],
	input vram_word_t d_in [N_CORES],
	output vram_word_t d_out [N_CORES],
	output logic ready [N_CORES],

	input vram_addr_t video_addr,
	output vram_word_t video_pixel,

	input vram_word_t sw_in
);

logic l2_en [N_CORES];
logic l2_w [N_CORES];
fb_addr_t l2_addr [N_CORES];
fb_word_t l2_in [N_CORES];
fb_word_t l2_out [N_CORES];
logic l2_ready [N_CORES];

logic invalidate [N_CORES];
fb_addr_t inv_addr;
logic invalidated [N_CORES];

logic fb_en;
logic fb_w;
fb_addr_t fb_addr;
fb_word_t fb_in;
fb_word_t fb_out;
logic fb_ready;

genvar i;
for (i = 0; i < N_CORES; i++) begin : gen_l1
	l1cache core_l1 (
		.clk(clk),
		.rst(rst),
		.en(en[i]),
		.w(w[i]),
		.addr(addr[i]),
		.d_in(d_in[i]),
		.d_out(d_out[i]),
		.ready(ready[i]),

		.l2_en(l2_en[i]),
		.l2_w(l2_w[i]),
		.l2_addr(l2_addr[i]),
		.l2_in(l2_in[i]),
		.l2_out(l2_out[i]),
		.l2_ready(l2_ready[i]),
		.invalidate(invalidate[i]),
		.inv_addr(inv_addr),
		.invalidated(invalidated[i]),

		.sw_in(sw_in)
	);
end

l2cache shared_l2 (
	.clk(clk),
	.rst(rst),
	.en(l2_en),
	.w(l2_w),
	.addr(l2_addr),
	.d_in(l2_in),
	.d_out(l2_out),
	.ready(l2_ready),

	.invalidate(invalidate),
	.inv_addr(inv_addr),
	.invalidated(invalidated),

	.fb_en(fb_en),
	.fb_w(fb_w),
	.fb_addr(fb_addr),
	.fb_in(fb_in),
	.fb_out(fb_out),
	.fb_ready(fb_ready)
);


framebuffer shared_fb (
	.clk(clk),
	.en(fb_en),
	.w(fb_w),
	.addr(fb_addr),
	.d_in(fb_in),
	.d_out(fb_out),
	.ready(fb_ready),

	.video_addr(video_addr),
	.video_pixel(video_pixel)
);

endmodule
