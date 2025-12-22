import attrs::*;
import cache_attrs::*;

module l1cache_tb();

logic clk, rst;

initial clk = 1'b1;
always #5 clk = ~clk;

logic en, w, ready, l2_en, l2_w, l2_ready, invalidate, invalidated;
vram_addr_t addr;
vram_word_t d_in, d_out, sw_in;
fb_addr_t l2_addr, inv_addr;
fb_word_t l2_in, l2_out;

l1cache l1cache_inst (.*);

`define OFFSET(addr) addr[2:0]
`define INDEX(addr) addr[8:3]
`define TAG(addr) addr[16:9]
`define L2ADDR(addr) {`TAG(addr), `INDEX(addr)}
`define LINEB(line, offset) line[(offset)*8 +: 8]

`define URANDLINE {$urandom(), $urandom()}
`define URANDADDR $urandom_range(0, VRAM_DEPTH-100)

initial begin
	assert ($bits(fb_addr_t) == ($bits(l1_idx_t) + $bits(l1_tag_t))) else
		$error("Bad FB addres width; wanth %0d, have %0d", $bits(l1_idx_t)+$bits(l1_tag_t), $bits(fb_addr_t));
end

vram_addr_t taddr;
vram_word_t test;
fb_word_t fbtest, fbtesttmp;
initial begin
	rst = 1'b1;
	en = 1'b0;
	w = 1'b0;
	l2_ready = 1'b0;
	invalidate = 1'b0;
	repeat (2) @(posedge clk);
	rst = 1'b0;

	// ensure cache tags are all invalidated
	#0;
	for (int i = 0; i < 64; i++) begin
		assert (l1cache_inst.valid[i] == 1'b0) else
			$error("Cache tags not invalid on reset");
	end
	@(posedge clk);

	// test refill
	fbtest = `URANDLINE;
	en = 1'b1;
	w = 1'b0;
	addr = `URANDADDR;
	taddr = addr;
	@(posedge clk);
	#0;
	assert (l2_en == 1'b1) else $error("L2 not enabled for refill");
	assert (l2_addr == (addr>>3)) else $error("Bad addr supplied to L2. Have %0d, want %0d", l2_addr, addr);
	assert (l2_w == 1'b0) else $error("Tried to write to L2 instead of read");
	l2_out = fbtest;
	l2_ready = 1'b1;
	@(posedge clk);
	l2_ready = 1'b0;
	@(posedge clk);
	#0;
	assert (l1cache_inst.valid[`INDEX(addr)] == 1'b1) else $error("Line is not marked valid");
	assert (l1cache_inst.tags[`INDEX(addr)] == `TAG(addr)) else $error("Tag is not stored correctly");
	assert (l1cache_inst.l1_bram.data[`INDEX(addr)] == fbtest) else $error("Line is not stored in cache. Have %0d, want %0d", l1cache_inst.l1_bram.data[`INDEX(addr)], fbtest);
	assert (l1cache_inst.hit == 1'b1) else $error("L1 misses a valid line");

	wait (ready) @(posedge clk);
	en = 1'b0;
	#0;
	assert (d_out == `LINEB(fbtest, `OFFSET(addr))) else $error("Bad L1 output. Have %0d, want %0d\n", d_out, `LINEB(fbtest, `OFFSET(addr)));


	// test write
	repeat (3) @(posedge clk);
	addr = addr + 9;
	test = $urandom();
	fbtest = `URANDLINE;
	fbtesttmp = fbtest;
	`LINEB(fbtesttmp, `OFFSET(addr)) = test;
	en = 1'b1;
	w = 1'b1;
	d_in = test;
	#0;
	assert (l2_en == 1'b1) else $error("L1 does not enable L2 during write refill");
	@(posedge clk);
	// here L1 should be requesting a refill
	l2_out = fbtest;
	l2_ready = 1'b1;
	@(posedge clk);
	l2_ready = 1'b0;
	@(posedge clk);
	#0;
	assert (l1cache_inst.valid[`INDEX(addr)] == 1'b1) else $error("Refill after write did not set valid");
	assert (l1cache_inst.tags[`INDEX(addr)] == `TAG(addr)) else $error("Invalid tag stored for refill after write");
	@(posedge clk);
	// L1 is requesting the line from the cache and latching it
	@(posedge clk);
	// L1 is writing to L2 and to its cache now
	assert (l2_en == 1'b1) else $error("L1 does not enable L2 during write");
	assert (l2_w == 1'b1) else $error("L1 does not write to L2 during write");
	assert (l2_addr == (addr>>3)) else $error("L1 gives wrong addr to L2");
	assert (l2_in == fbtesttmp) else $error("L1 gives wrong line to L2");
	repeat (2) @(posedge clk);
	l2_ready = 1'b1;
	@(posedge clk);
	l2_ready = 1'b0;
	wait (ready);
	en = 1'b0;
	w = 1'b0;
	#0;
	assert (l1cache_inst.l1_bram.data[`INDEX(addr)] == fbtesttmp) else $error("L1 stores the wrong line after write");

	// test invalidation
	assert ((l1cache_inst.valid[`INDEX(addr)] == 1'b1)
	      && l1cache_inst.tags[`INDEX(addr)] == `TAG(addr)) else
		$error("Previous cache line not stored in cache");
	repeat (3) @(posedge clk);
	inv_addr = `L2ADDR(addr);
	invalidate = 1'b1;
	#0;
	assert (l1cache_inst.invhit == 1'b1) else $error("Invalidated line not line L1");
	wait (invalidated);
	#1;
	@(posedge clk);
	invalidate = 1'b0;
	#1;
	assert (l1cache_inst.valid[`INDEX(addr)] == 1'b0) else $error("Invalidation failed");

	// test reading valid line
	repeat (2) @(posedge clk);
	addr = taddr;
	en = 1'b1;
	#0;
	assert (l1cache_inst.hit == 1'b1) else $error("Cache miss for valid line");
	@(posedge clk);
	assert (l2_en == 1'b0) else $error("L1 fetches a valid line from L2");
	wait (ready);
	@(posedge clk);
	en = 1'b0;

	// test invalidation during read
	repeat (2) @(posedge clk);
	addr = taddr;
	en = 1'b1;
	@(posedge clk);
	inv_addr = `L2ADDR(taddr);
	invalidate = 1'b1;
	#1;
	fbtest = 67;
	assert (l1cache_inst.hit == 1'b1) else $error("Miss when invalidation during transaction");
	assert (invalidated == 1'b0) else $error("L1 is responding to invalidation during transaction");
	wait (ready) @(posedge clk);
	en = 1'b0;
	wait (invalidated) @(posedge clk);
	invalidate = 1'b0;
	@(posedge clk);
	#1;
	assert (l1cache_inst.valid[`INDEX(addr)] == 1'b0) else $error("Invalidation never happened");

	repeat (2) @(posedge clk);
	$finish();
end
endmodule
