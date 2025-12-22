import attrs::*;

module core_top (
	input logic clk,

	input [7:0] sw_i,
	output [7:0] led_o,

	input uart_rtl_0_rxd,
	output uart_rtl_0_txd,

	input reset_rtl_0,

	output logic hdmi_clk_p, hdmi_clk_n,
	output logic [2:0] hdmi_tx_p,
	output logic [2:0] hdmi_tx_n
);
    logic clk_s;
    logic clk_100mhz;
	logic clk_25mhz;
	logic clk_125mhz;

	logic [7:0] sw_s;

	logic core_rst, rom_ready[N_CORES], rom_active[N_CORES], vram_ready[N_CORES], vram_active[N_CORES], vram_w[N_CORES];
	ir_word_t rom_out[N_CORES];
	rom_addr_t rom_addr[N_CORES];
	vram_word_t vram_out[N_CORES], vram_in[N_CORES];
	vram_addr_t vram_addr[N_CORES];

	vram_addr_t video_addr;
	vram_word_t video_pixel;
	logic [9:0] drawX, drawY;
	logic [8:0] smallX;
	logic [7:0] smallY;
	logic hsync, vsync, vde;
	logic locked;

	logic prog, p_avail, p_ready, p_lo_ack;
	ir_word_t p_d_in;

	// Y * 320 + X
	// Y * 320 = (Y << 8) + (Y << 6)
	assign smallX = drawX[9:1];
	assign smallY = drawY[9:1];
	assign video_addr = (smallY << 8) + (smallY << 6) + smallX;

    datapaths cores (
        .clk(clk_s),
        .rst(core_rst),
        .rom_out(rom_out),
        .rom_ready(rom_ready),
        .rom_addr(rom_addr),
        .rom_active(rom_active),
        .vram_out(vram_out),
        .vram_ready(vram_ready),
        .vram_addr(vram_addr),
        .vram_in(vram_in),
        .vram_active(vram_active),
        .vram_w(vram_w)
    );

	prog_rom prog_rom_inst (
		.clk(clk_s),
		.prog(prog),
		.p_avail(p_avail),
		.p_d_in(p_d_in),
		.p_ready(p_ready),
		.p_lo_ack(p_lo_ack),
		.active(rom_active),
		.addr(rom_addr),
		.d_out(rom_out),
		.ready(rom_ready),
		.core_rst(core_rst)
	);

//	ezvram ezvram_inst (
//		.clk(clk_s),
//		.rst(core_rst),
//		.d_out(vram_out),
//		.ready(vram_ready),
//		.addr(vram_addr),
//		.d_in(vram_in),
//		.active(vram_active),
//		.w(vram_w),
//		.sw_in(sw_s),
//		.reg_out(led_o)
//	);

//	block_vram vram_inst (
//		.clk(clk_s),
//		.rst(core_rst),
//		.d_out(vram_out),
//		.ready(vram_ready),
//		.addr(vram_addr),
//		.d_in(vram_in),
//		.active(vram_active),
//		.w(vram_w),
//
//		.video_addr(video_addr),
//		.video_pixel(video_pixel)
//	);

	vram vram_inst (
		.clk(clk_s),
		.rst(core_rst),
		.en(vram_active),
		.w(vram_w),
		.addr(vram_addr),
		.d_in(vram_in),
		.d_out(vram_out),
		.ready(vram_ready),

		.video_addr(video_addr),
		.video_pixel(video_pixel),

		.sw_in(sw_s)
	);

	vga_controller vga_inst (
		.pixel_clk(clk_25mhz),
		.reset(reset_rtl_0),
		.hs(hsync),
		.vs(vsync),
		.active_nblank(vde),
		.drawX(drawX),
		.drawY(drawY)
	);

	hdmi_tx_0 vga_to_hdmi (
		//Clocking and Reset
		.pix_clk(clk_25mhz),
		.pix_clkx5(clk_125mhz),
		.pix_clk_locked(locked),
		.rst(reset_rtl_0),
		//Color and Sync Signals
		.red(video_pixel[7:5]),
		.green(video_pixel[4:2]),
		.blue(video_pixel[1:0]),
		.hsync(hsync),
		.vsync(vsync),
		.vde(vde),

		//aux Data (unused)
		.aux0_din(4'b0),
		.aux1_din(4'b0),
		.aux2_din(4'b0),
		.ade(1'b0),

		//Differential outputs
		.TMDS_CLK_P(hdmi_clk_p),
		.TMDS_CLK_N(hdmi_clk_n),
		.TMDS_DATA_P(hdmi_tx_p),
		.TMDS_DATA_N(hdmi_tx_n)
	);

	microblaze microblaze_inst (
		.clk_100MHz(clk_100mhz),
		.gpio_p_avail_tri_o(p_avail),
		.gpio_p_d_in_tri_o(p_d_in),
		.gpio_p_lo_ack_tri_i(p_lo_ack),
		.gpio_p_ready_tri_i(p_ready),
		.gpio_prog_tri_o(prog),
		.reset_rtl_0(~reset_rtl_0),
		.uart_rtl_0_rxd(uart_rtl_0_rxd),
		.uart_rtl_0_txd(uart_rtl_0_txd)
	);

	sync sync_sw (
		.clk(clk_s),
		.in(sw_i),
		.out(sw_s)
	);

	clk_wiz_0 clk_wiz_inst (
	   .reset(reset_rtl_0),
	   .clk_in1(clk),
	   .clk_out_50mhz(clk_s),
	   .clk_out_100mhz(clk_100mhz),
	   .clk_out_125mhz(clk_125mhz),
	   .clk_out_25mhz(clk_25mhz),
	   .locked(locked)
	);
endmodule


//module ezvram (
//	input logic clk, rst,
//	output vram_word_t d_out,
//	output logic ready,
//	input vram_addr_t addr,
//	input vram_word_t d_in,
//	input logic active, w,
//
//	input vram_word_t sw_in,
//	output vram_word_t reg_out
//);
//
//	always_ff @(posedge clk) begin
//		if (active) begin
//			if (w) reg_out <= d_in;
//			d_out <= sw_in;
//		end
//
//		ready <= active;
//	end
//endmodule

//module block_vram (
//	input logic clk, rst,
//	output vram_word_t d_out,
//	output logic ready,
//	input vram_addr_t addr,
//	input vram_word_t d_in,
//	input logic active, w,
//
//	input vram_addr_t video_addr,
//	output vram_word_t video_pixel
//);
//	dp_bram #(
//		.WIDTH(VRAM_WIDTH),
//		.DEPTH(160*120)
//	) vram_bram (
//		// core port
//		.clk(clk),
//		.ena(active),
//		.wa(w),
//		.addra(addr),
//		.d_ina(d_in),
//		.d_outa(d_out),
//		.readya(ready),
//
//		// video port
//		.enb(1'b1),
//		.wb(1'b0),
//		.addrb(video_addr),
//		.d_inb(),
//		.d_outb(video_pixel),
//		.readyb()
//	);
//endmodule

module sync (
	input logic clk,
	input logic [7:0] in,
	output logic [7:0] out
);
	localparam int COUNTER_WIDTH = 14;

	logic [7:0] ff1, ff2;
	logic [COUNTER_WIDTH : 0] counter;

	always_ff @(posedge clk) begin
		ff1 <= in;
		ff2 <= ff1;

		if (~&(ff1 ^ ff2)) begin
		  if (~counter[COUNTER_WIDTH]) begin
		      counter <= counter + 1'b1;
		  end else begin
		      out <= ff2;
		  end
	    end else begin
	       counter <= '0;
	    end
	end
endmodule

module datapaths (
    input logic clk, rst,
    input ir_word_t rom_out[N_CORES],
    input logic rom_ready[N_CORES],
    output rom_addr_t rom_addr[N_CORES],
    output logic rom_active[N_CORES],
    input vram_word_t vram_out[N_CORES],
    input logic vram_ready[N_CORES],
    output vram_addr_t vram_addr[N_CORES],
    output vram_word_t vram_in[N_CORES],
    output logic vram_active[N_CORES],
    output logic vram_w[N_CORES]
);
	genvar i;
	for (i = 0; i < N_CORES; i++) begin : gen_datapaths
		datapath datapath_inst (
			.clk(clk),
			.rst(rst),
			.core_id(i),
			.rom_out(rom_out[i]),
			.rom_ready(rom_ready[i]),
			.rom_addr(rom_addr[i]),
			.rom_active(rom_active[i]),
			.vram_out(vram_out[i]),
			.vram_ready(vram_ready[i]),
			.vram_addr(vram_addr[i]),
			.vram_in(vram_in[i]),
			.vram_active(vram_active[i]),
			.vram_w(vram_w[i])
		);
	end
endmodule