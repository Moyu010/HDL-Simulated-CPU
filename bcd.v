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
