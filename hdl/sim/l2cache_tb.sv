import attrs::*;
import cache_attrs::*;

module l2cache_tb ();

logic clk, rst;

initial clk = 1'b1;
always #5 clk = ~clk;

logic en[N_CORES];
logic w[N_CORES];
fb_addr_t addr[N_CORES];
fb_word_t d_in[N_CORES];
fb_word_t d_out[N_CORES];
logic ready[N_CORES];
logic invalidate[N_CORES];
fb_addr_t inv_addr;
logic invalidated[N_CORES];
logic fb_en, fb_w;
fb_addr_t fb_addr;
fb_word_t fb_in, fb_out;
logic fb_ready;

l2cache l2cache_inst (.*);

core_id_t grant;
logic grant_ready;
assign grant = l2cache_inst.grant;
assign grant_ready = l2cache_inst.grant_ready;

initial begin
	for (int i = 0; i < N_CORES; i++) begin
		en[i] = 1'b0;
		w[i] = 1'b0;
		addr[i] = 0;
		d_in[i] = 0;
		invalidated[i] = 1'b0;
	end
	fb_out = 0;
	fb_ready = 0;

	rst = 1'b1;
	repeat (2) @(posedge clk);
	rst = 1'b0;

	// single core read
	@(posedge clk);
	#1;
	w[0] = 1'b0;
	addr[0] = 14'd17;
	en[0] = 1'b1;
	wait (fb_en);
	#1;
	assert (fb_w == 1'b0) else $error("FB w during read");
	assert (fb_addr == 14'd17) else $error("Bad addr to FB");
	repeat (2) @(posedge clk);
	fb_out = 64'h6768697071727374;
	fb_ready = 1'b1;
	@(posedge clk);
	fb_ready = 1'b0;
	wait (ready[0]);
	en[0] = 1'b0;
	#0;
	assert (d_out[0] == fb_out) else $error("bad output");

	@(posedge clk);
	#1;
	addr[2] = 14'd13724;
	en[2] = 1'b1;
	wait (fb_en);
	#1;
	assert (fb_addr == addr[2]) else $error("Bad addr to FB");
	repeat (2) @(posedge clk);
	fb_out = 64'h1000000000000001;
	fb_ready = 1'b1;
	@(posedge clk);
	fb_ready = 1'b0;
	assert (l2cache_inst.grant == 2'd2) else $error("arbiter did not grant");
	wait (ready[2]);
	en[2] = 1'b0;
	#0;
	assert (d_out[2] == fb_out) else $error("bad output");

	// test write
	@(posedge clk);
	#1;
	addr[1] = 14'd243;
	d_in[1] = 64'hdeadbeeffeddeeda;
	w[1] = 1'b1;
	en[1] = 1'b1;
	wait (fb_en);
	#1;
	assert (fb_addr == addr[1]) else $error("Bad addr to FB");
	assert (fb_in == d_in[1]) else $error("Bad FB input");
	assert (fb_w == 1'b1) else $error("Not writing to FB");
	@(posedge clk);
	fb_ready = 1'b1;
	@(posedge clk);
	fb_ready = 1'b0;
	wait (ready[1]);
	en[1] = 1'b0;
	#1;
	for (int i = 0; i < N_CORES; i++) begin
		assert (invalidate[i] == 1'b1) else $error("No invalidation after write");
	end
	@(posedge clk);


	// concurrent readers
	@(posedge clk);
	addr[0] = 14'd123;
	addr[1] = 14'd321;
	addr[2] = 14'd555;
	w[0] = 1'b0;
	w[1] = 1'b0;
	w[2] = 1'b0;
	en[0] = 1'b1;
	en[1] = 1'b1;
	en[2] = 1'b1;
	for (int j = 0; j < 3; j++) begin
		#1;
		wait (fb_en);
		@(posedge clk);
		#1;
		fb_out = fb_addr;
		fb_ready = 1'b1;
		@(posedge clk);
		fb_ready = 1'b0;
		wait (|ready);
		#1;
		for (int i = 0; i < 3; i++) if (ready[i]) begin
			en[i] = 1'b0;
			assert (d_out[i] == addr[i]) else $error("bad read for %0d", i);
		end
	end
	@(posedge clk);

	repeat (2) @(posedge clk);
	$finish();
end
endmodule
