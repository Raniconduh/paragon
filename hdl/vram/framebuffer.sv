import attrs::*;

module framebuffer (
	input logic clk, // synchronize to cores
	input logic en, w,
	input fb_addr_t addr,
	input fb_word_t d_in,
	output fb_word_t d_out,
	output logic ready,

	input vram_addr_t video_addr,
	output vram_word_t video_pixel
);
	// framebuffer is 64 bits wide which is 8 bytes
	// so pixels are addressed in the framebuffer by the upper N-3 bits.
	// the lower 3 bits address the byte inside the framebuffer block
	fb_addr_t pixel_addr;
	fb_word_t fb_block;
	assign pixel_addr = video_addr[$high(video_addr):3];
	assign video_pixel = fb_block[video_addr[2:0]*8 +: 8];

	// somehow, a TDP BRAM configured as 64x9600 uses fewer RAMB blocks than
	// an equivalently configured SP BRAM. To keep the interface simple
	// between the frambuffer and caches, the data buses are 64 bits wide.
	// This allows caches to use fewer RAMB blocks.
	// it seems 64 bit data buses is the optimal wrt block usage
	dp_bram #(
		.WIDTH(FB_WIDTH),
		.DEPTH(FB_DEPTH)
	) fb_bram (
		.clk(clk),
		.ena(en),
		.wa(w),
		.addra(addr),
		.d_ina(d_in),
		.d_outa(d_out),
		.readya(ready),

		.enb(1'b1),
		.wb(1'b0),
		.addrb(pixel_addr),
		.d_inb(),
		.d_outb(fb_block),
		.readyb()
	);
endmodule
