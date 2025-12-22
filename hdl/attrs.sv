package attrs;
	localparam int N_CORES = 12;
	localparam int CORE_ID_WIDTH = $clog2(N_CORES);

	localparam int CORE_WORD_WIDTH = 24;
	localparam int IR_WIDTH = 16;

	localparam int OPCODE_WIDTH = 4;

	localparam int N_REGS = 16;
	localparam int REG_ADDR_WIDTH = $clog2(N_REGS);

	localparam int ALU_OP_WIDTH = 3;

	localparam int ROM_DEPTH = 2048;
	localparam int ROM_ADDR_WIDTH = $clog2(ROM_DEPTH);

	localparam int VRAM_WIDTH = 8;
	localparam int VRAM_DEPTH = 320 * 240;
	localparam int VRAM_ADDR_WIDTH = $clog2(VRAM_DEPTH);

	localparam int FB_WIDTH = 64;
	localparam int FB_DEPTH = VRAM_DEPTH * VRAM_WIDTH / FB_WIDTH;
	localparam int FB_ADDR_WIDTH = $clog2(FB_DEPTH);

	typedef logic[CORE_ID_WIDTH-1:0] core_id_t;
	typedef logic[CORE_WORD_WIDTH-1:0] core_word_t;
	typedef logic[REG_ADDR_WIDTH-1:0] reg_addr_t;

	typedef logic[IR_WIDTH-1:0] ir_word_t;
	typedef logic[ROM_ADDR_WIDTH-1:0] rom_addr_t;

	typedef logic[VRAM_WIDTH-1:0] vram_word_t;
	typedef logic[VRAM_ADDR_WIDTH-1:0] vram_addr_t;

	typedef logic[FB_WIDTH-1:0] fb_word_t;
	typedef logic[FB_ADDR_WIDTH-1:0] fb_addr_t;
endpackage
