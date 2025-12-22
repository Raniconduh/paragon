// customizable register (nice for viewing block diagrams
module register #(
	parameter int WIDTH = 8
)(
	input logic clk, rst,
	input logic w,
	input logic [WIDTH-1:0] d,
	output logic [WIDTH-1:0] q
);

	always_ff @(posedge clk) begin
		if (rst) q <= 0;
		else if (w) q <= d;
	end
endmodule
