module analysis (in1, out, clk);
	parameter IN_BIT = 16;
	parameter OUT_BIT = 16;

	input [IN_BIT-1:0] in1;
	// input [IN_BIT-1:0] in2;
	// input [3:0] in3;
	output reg [OUT_BIT-1:0] out;
	input clk;

	reg [IN_BIT-1:0] clocked_in1;
	// reg [IN_BIT-1:0] clocked_in2;
	// reg [3:0] clocked_in3;
	wire [OUT_BIT-1:0] clocked_out;
	
	always @(posedge clk) begin
		clocked_in1 <= in1;
		// clocked_in2	<= in2;
		// clocked_in3 <= in3;
		out <= clocked_out;
	end
 	// sign_extend test (clocked_in1, clocked_out);
	// tick_FSM tick_fsm(.rst(1'b0), .clk(clk), .tick(clocked_out), .enable(1'b1));
	// multiplexer mux (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, clocked_in1, clocked_out);
	// ALU alu(clocked_in1, clocked_in2, clocked_in3, clocked_out);
	// register_n #(16) reg1 (clocked_in1, 1'b1, clk, clocked_out, 1'b0);
	register_n #(.N(9)) reg1 (clocked_in1, 1'b1, clk, clocked_out, 1'b0);
endmodule


