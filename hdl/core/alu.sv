import attrs::*;
import opcode::*;

module alu (
	input core_word_t d_in1, d_in2,
	input opcode_t op,
	input logic shl, sha,

	output logic carryout,
	output core_word_t d_out
);

	always_comb begin
		carryout = 0;
		d_out = 0;

		case (op)
		OP_ADD,
		OP_ADDI,
		OP_AIPC : {carryout, d_out} = d_in1 + d_in2;
		OP_SUB  : {carryout, d_out} = d_in1 + ~d_in2 + 1;
		OP_MUL  : d_out = d_in1 * d_in2;
		OP_AND  : d_out = d_in1 & d_in2;
		OP_OR   : d_out = d_in1 | d_in2;
		OP_XOR  : d_out = d_in1 ^ d_in2;
		OP_NOT  : d_out = ~d_in1;
		OP_SH   : begin
			case ({shl, sha})
			2'b00 : d_out = d_in1 >> d_in2;
			2'b01 : d_out = $signed(d_in1) >>> d_in2;
			2'b10 : d_out = d_in1 << d_in2;
			default : d_out = 0;
			endcase
		end
		default : d_out = 0;
		endcase
	end
endmodule
