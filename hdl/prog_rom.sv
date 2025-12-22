import attrs::*;

module prog_rom #(
	localparam int N_DPBRAMS = (N_CORES + 1)/2
)(
	input logic clk,

	// programming pins
	input logic prog,
	input logic p_avail,
	input ir_word_t p_d_in,
	output logic p_ready,
	output logic p_lo_ack,

	// instruction pins
	input logic active [N_CORES], // enable pin
	input rom_addr_t addr [N_CORES],
	output ir_word_t d_out [N_CORES],
	output logic ready [N_CORES],

	// during programming, the cores must be held in reset
	output logic core_rst
);

	logic bram_w;
	// addresses and enables will be multiplexed by the programming sigal
	logic bram_en [2*N_DPBRAMS];
	rom_addr_t bram_addr [2*N_DPBRAMS];
	ir_word_t bram_out [2*N_DPBRAMS];
	logic bram_ready [2*N_DPBRAMS];

	// hardcode enable signals for BRAM ports which aren't used
	genvar i;
	for (i = N_CORES; i < 2*N_DPBRAMS; i++) begin : gen_bad_bram_signals
		assign bram_en[i] = 0;
		assign bram_addr[i] = 0;
	end

	// only connect BRAM signals from ports which correspond to real cores
	for (i = 0; i < N_CORES; i++) begin : gen_bram_nets
		assign d_out[i] = bram_out[i];
		assign ready[i] = bram_ready[i];
	end

	for (i = 0; i < N_DPBRAMS; i++) begin : gen_brams
		dp_bram #(
			.WIDTH(IR_WIDTH),
			.DEPTH(ROM_DEPTH)
		) dp_rom (
			.clk(clk),

			.ena(bram_en[2*i]),
			.wa(bram_w),
			.addra(bram_addr[2*i]),
			.d_ina(p_d_in),
			.d_outa(bram_out[2*i]),
			.readya(bram_ready[2*i]),

			// never write to port B, otherwise it will cause write collisions
			.enb(bram_en[2*i+1]),
			.wb(0),
			.addrb(bram_addr[2*i+1]),
			.d_inb(p_d_in),
			.d_outb(bram_out[2*i+1]),
			.readyb(bram_ready[2*i+1])
		);
	end


	logic prog_rising, prog_ff;
	rom_addr_t counter, next_counter;

	// programming FSM
	enum logic [2:0] {
		s_reset,
		s_idle,
		s_write,
		s_commit,
		s_written
	} state, next_state;

	// prog_rising is high for 1 clock cycle when prog is first asserted
	assign prog_rising = prog & ~prog_ff;
	assign core_rst = prog_ff;

	always_comb begin
		// initialize signals to prevent latching
		next_state = state;
		next_counter = counter;
		p_ready = 0;
		p_lo_ack = 0;
		bram_w = 0;
		for (int i = 0; i < N_CORES; i++) bram_en[i] = 0;
		for (int i = 0; i < N_CORES; i++) bram_addr[i] = 0;

		if (prog_rising) begin
			next_state = s_reset;
		// programming FSM
		end else if (prog_ff) begin
			case (state)
				s_reset : begin
					next_counter = 0;
					next_state = s_idle;
				end

				s_idle : begin
					p_lo_ack = 1;
					if (p_avail) next_state = s_write;
					else next_state = s_idle;
				end

				s_write : begin
					for (int i = 0; i < N_CORES; i += 2) begin
						bram_addr[i] = counter;
						bram_en[i] = 1;
						bram_w = 1;
					end
					next_state = s_commit;
				end

				s_commit : begin
					for (int i = 0; i < N_CORES; i += 2) begin
						bram_addr[i] = counter;
						bram_en[i] = 1;
						bram_w = 1;
					end
					next_counter = counter + 1;
					next_state = s_written;
				end

				s_written : begin
					p_ready = 1;
					if (p_avail) next_state = s_written;
					else next_state = s_idle;
				end
			endcase
		// instruction fetch
		end else begin
			for (int i = 0; i < N_CORES; i++) begin
				bram_en[i] = active[i];
				bram_addr[i] = addr[i];
			end
		end
	end

	always_ff @(posedge clk) begin
		prog_ff <= prog;
		counter <= next_counter;
		state <= next_state;
	end
endmodule
