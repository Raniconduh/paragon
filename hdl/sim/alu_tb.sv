import attrs::*;
import opcode::*;

module alu_tb ();
	logic clk;

	core_word_t d_in1, d_in2, d_out;
	alu_opcode_t op;
	logic shl, sha, carryout;

	alu alu_inst (
		.d_in1(d_in1),
		.d_in2(d_in2),
		.op(op),
		.shl(shl),
		.sha(sha),
		.carryout(carryout),
		.d_out(d_out)
	);

	initial begin
		// add
		op = ALU_OP_ADD;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom();
			#10;

			assert ({carryout, d_out} == (d_in1 + d_in2)) else $error("Addition failed");
		end
		// sub
		op = ALU_OP_SUB;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom();
			#10;

			assert (d_out == (d_in1 - d_in2)) else $error("Subtraction failed");
		end
		// mul
		op = ALU_OP_MUL;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom();
			#10;

			assert (d_out == (d_in1 * d_in2)) else $error("Multiplication failed");
		end
		// and
		op = ALU_OP_AND;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom();
			#10;

			assert (d_out == (d_in1 & d_in2)) else $error("AND failed");
		end
		// or
		op = ALU_OP_OR;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom();
			#10;

			assert (d_out == (d_in1 | d_in2)) else $error("OR failed");
		end
		// xor
		op = ALU_OP_XOR;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom();

			#10;
			assert (d_out == (d_in1 ^ d_in2)) else $error("XOR failed");
		end
		// not
		op = ALU_OP_NOT;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom();

			#10;
			assert (d_out == (~d_in1)) else $error("NOT failed");
		end
		// shl
		op = ALU_OP_SH;
		shl = 1; sha = 0;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom_range(0, 23);
			#10;

			assert (d_out == (d_in1 << d_in2)) else $error("Left shift failed");
		end
		// shr
		op = ALU_OP_SH;
		shl = 0; sha = 0;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom_range(0, 23);
			#10;

			assert (d_out == (d_in1 >> d_in2)) else $error("Right shift failed");
		end
		// sha
		op = ALU_OP_SH;
		shl = 0; sha = 1;
		repeat (20) begin
			d_in1 = $urandom();
			d_in2 = $urandom_range(0, 23);
			#10;

			assert (d_out == (d_in1 >>> d_in2)) else $error("Arithmetic shift failed");
		end
		$finish();
	end
endmodule
