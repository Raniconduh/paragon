// customizable true dual port BRAM
module dp_bram #(
	parameter int WIDTH = 8,
	parameter int DEPTH = 1024,

	localparam int ADDR_WIDTH = $clog2(DEPTH)
)(
	input logic clk,

	// port A
	input logic ena,
	input logic wa,
	input logic [ADDR_WIDTH-1:0] addra,
	input logic [WIDTH-1:0] d_ina,
	output logic [WIDTH-1:0] d_outa,
	output logic readya,

	// port B
	input logic enb,
	input logic wb,
	input logic [ADDR_WIDTH-1:0] addrb,
	input logic [WIDTH-1:0] d_inb,
	output logic [WIDTH-1:0] d_outb,
	output logic readyb
);
	(* ram_style = "block" *)
	logic [WIDTH-1:0] data [DEPTH];

	// port A
	always_ff @(posedge clk) begin
		if (ena) begin
			if (wa) data[addra] <= d_ina;
			d_outa <= data[addra];
		end

		readya <= ena;
	end

	// port B
	always_ff @(posedge clk) begin
		if (enb) begin
			if (wb) data[addrb] <= d_inb;
			d_outb <= data[addrb];
		end

		readyb <= enb;
	end
endmodule


// customizable single port BRAM
module sp_bram #(
	parameter int WIDTH = 8,
	parameter int DEPTH = 1024,

	localparam int ADDR_WIDTH = $clog2(DEPTH)
)(
	input logic clk,
	input logic ena, wa,
	input logic [ADDR_WIDTH-1:0] addra,
	input logic [WIDTH-1:0] d_ina,
	output logic [WIDTH-1:0] d_outa,
	output logic readya
);

	(* ram_style = "block" *)
	logic [WIDTH-1:0] data [DEPTH];

	always_ff @(posedge clk) begin
		if (ena) begin
			if (wa) data[addra] <= d_ina;
			d_outa <= data[addra];
		end

		readya <= ena;
	end
endmodule
