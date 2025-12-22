package cache_attrs;
	localparam int L1_WIDTH = attrs::FB_WIDTH;
	localparam int L1_DEPTH = 64;

	// ranges in core address
	localparam int L1ADDROFF_HI = 2;
	localparam int L1ADDROFF_LO = 0;

	localparam int L1ADDRIDX_HI = 8;
	localparam int L1ADDRIDX_LO = 3;

	localparam int L1ADDRTAG_HI = 16;
	localparam int L1ADDRTAG_LO = 9;

	// ranges in framebuffer address
	localparam int L1FBADDRIDX_HI = 5;
	localparam int L1FBADDRIDX_LO = 0;

	localparam int L1FBADDRTAG_HI = 13;
	localparam int L1FBADDRTAG_LO = 6;

	// L2 attributes
	localparam int L2_WIDTH = attrs::FB_WIDTH;
	localparam int L2_DEPTH = L1_DEPTH * attrs::N_CORES;

	localparam int L2ADDRIDX_LO = 0;
	localparam int L2ADDRIDX_HI = $clog2(L2_DEPTH) - 1;

	localparam int L2ADDRTAG_LO = L2ADDRIDX_LO + 1;
	localparam int L2ADDRTAG_HI = attrs::FB_ADDR_WIDTH - 1;

	typedef logic[L1ADDROFF_HI-L1ADDROFF_LO:0] l1_off_t;
	typedef logic[L1ADDRIDX_HI-L1ADDRIDX_LO:0] l1_idx_t;
	typedef logic[L1ADDRTAG_HI-L1ADDRTAG_LO:0] l1_tag_t;

	typedef logic[L2ADDRIDX_HI-L2ADDRIDX_LO:0] l2_idx_t;
	typedef logic[L2ADDRTAG_HI-L2ADDRTAG_LO:0] l2_tag_t;

	// parameter checks
	typedef int _l1_invalid_width[(L1_WIDTH == 64) ? 1 : -1];
	typedef int _l1_invalid_vram_depth[(attrs::VRAM_DEPTH == 320*240) ? 1 : -1];
endpackage
