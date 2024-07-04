module sign_extend(in, ext);
	/* 
	 * This module sign extends the 9-bit Din to a 16-bit output.
	 */
	// TODO: Declare inputs and outputs
	parameter IN = 9, OUT = 16;
	input [IN-1:0] in;
	output [OUT-1:0] ext;
	// TODO: implement logic
	assign ext = {{(OUT-IN){in[IN-1]}}, in};
endmodule



module tick_FSM(rst, clk, enable, tick);
	/* 
	 * This module implements a tick FSM that will be used to
	 * control the actions of the control unit
	 */
	
	// TODO: Declare inputs and outputs
	input clk, rst, enable;
	output reg [3:0] tick;
	parameter TICK1 = 4'b0001, TICK2 = 4'b0010, TICK3 = 4'b0100, TICK4 = 4'b1000;
    // TODO: implement FSM
	initial begin 
		tick <= TICK1;
	end

	always @(posedge clk) begin
		if (rst) begin
			tick <= TICK1;
		end else if (enable) begin
			case (tick)
				TICK1: tick <= TICK2;
				TICK2: tick <= TICK3;
				TICK3: tick <= TICK4;
				TICK4: tick <= TICK1;
				default: tick <= TICK1;
			endcase
		end
	end
endmodule

module multiplexer(SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
	/* 
	 * This module takes 10 inputs and places the correct input onto the bus.
	 */
	// TODO: Declare inputs and outputs
	input [15:0] SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G;
	input [3:0] sel;
	output reg [15:0] Bus;
	parameter SEL_G = 4'd8, SEL_SIGNEXTDIN = 4'd9;
	// TODO: implement logic
	always @(*) begin
		case (sel)
			4'd0: Bus <= R0;
			4'd1: Bus <= R1;
			4'd2: Bus <= R2;
			4'd3: Bus <= R3;
			4'd4: Bus <= R4;
			4'd5: Bus <= R5;
			4'd6: Bus <= R6;
			4'd7: Bus <= R7;
			SEL_G: Bus <= G;
			SEL_SIGNEXTDIN: Bus <= SignExtDin;
			// default to give all 0
			default: Bus <= 16'd0;
		endcase
	end
endmodule

module ALU (input_a, input_b, alu_op, result);
	/* 
	 * This module implements the arithmetic logic unit of the processor.
	 */
	// TODO: declare inputs and outputs
	input wire signed [15:0] input_a, input_b;
	input [2:0] alu_op;
	output reg signed [15:0] result;
	parameter ALU_ADD = 3'b000, ALU_SUB = 3'b001, ALU_MUL = 3'b010, ALU_SLL = 3'b011, ALU_SRL = 3'b100;
	// TODO: Implement ALU Logic:
	always @(*) begin
		case (alu_op)
			default: result <= 16'b0; // rest are don't cares
			ALU_ADD: result <= input_a + input_b;
			ALU_SUB: result <= input_a - input_b;
			ALU_MUL: result <= input_a * input_b;
			ALU_SLL: result <= input_b << 1;
			ALU_SRL: result <= input_b >> 1;
		endcase
	end
endmodule



module register_n(r_in, enable, clk, Q, rst);
	// To set parameter N during instantiation, you can use:
	// register_n #(.N(num_bits)) reg_IR(.....), 
	// where num_bits is how many bits you want to set N to
	// and "..." is your usual input/output signals

	parameter N = 16;

	/* 
	 * This module implements registers that will be used in the processor.
	 */
	// TODO: Declare inputs, outputs, and parameter:
	input [N-1:0] r_in;
	input enable, clk, rst;
	output reg [N-1:0] Q;

	initial begin
		Q = {N{1'b0}};
	end

	// TODO: Implement register logic:
	always @(posedge clk) begin
		Q <= Q; // default
		if (rst) begin
			Q <= {N{1'b0}};
		end else if (enable) begin
			Q <= r_in;
		end
	end
endmodule


module bcd_out(in, hex);
  input [3:0] in;
  output reg [6:0] hex;
  
  always @(*) begin
    case (in)
      4'd0: hex = 7'b1000000;
      4'd1: hex = 7'b1111001;
      4'd2: hex = 7'b0100100;
      4'd3: hex = 7'b0110000;
      4'd4: hex = 7'b0011001;
      4'd5: hex = 7'b0010010;
      4'd6: hex = 7'b0000010;
      4'd7: hex = 7'b1111000;
      4'd8: hex = 7'b0000000;
      4'd9: hex = 7'b0010000;
      default: hex = 7'b1111111;
    endcase
  end
endmodule

module bcd_chain_5(bit_input, hex_out0, hex_out1, hex_out2, hex_out3, hex_out4);
    input [15:0] bit_input;
    output [6:0] hex_out0, hex_out1, hex_out2, hex_out3, hex_out4;

    wire [15:0] quotient [3:0];
    wire [13:0] remainder [3:0];
    
    div div_inst4 (.denom(14'd10000), .numer(bit_input), .quotient(quotient[3]), .remain(remainder[3]));
    div div_inst3 (.denom(14'd1000), .numer(remainder[3]), .quotient(quotient[2]), .remain(remainder[2]));
    div div_inst2 (.denom(14'd100), .numer(remainder[2]), .quotient(quotient[1]), .remain(remainder[1]));
    div div_inst1 (.denom(14'd10), .numer(remainder[1]), .quotient(quotient[0]), .remain(remainder[0]));

    bcd_out bcd_inst4 (.in(quotient[3][3:0]), .hex(hex_out4));
    bcd_out bcd_inst3 (.in(quotient[2][3:0]), .hex(hex_out3));
    bcd_out bcd_inst2 (.in(quotient[1][3:0]), .hex(hex_out2));
    bcd_out bcd_inst1 (.in(quotient[0][3:0]), .hex(hex_out1));
    bcd_out bcd_inst0 (.in(remainder[0][3:0]), .hex(hex_out0));

endmodule

