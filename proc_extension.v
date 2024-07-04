module proc_extension(SW, KEY, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
    input [9:0] SW;
    input [0:0] KEY;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    wire [8:0] din;
    assign din = SW[8:0];
    wire [15:0] bus;
    wire rst = SW[9];
    wire clk = ~KEY[0];
    wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7, display;
    wire [3:0] tick_FSM;
    assign LEDR[9:0] = bus[9:0];

    bcd_out bcd(tick_FSM, HEX5);

    bcd_chain_5 chain(.bit_input(display), .hex_out4(HEX4), .hex_out3(HEX3), .hex_out2(HEX2), .hex_out1(HEX1), .hex_out0(HEX0));

    simple_proc_ext proc(.clk(clk), .rst(rst), .din(din), .bus(bus), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7), .tick_FSM(tick_FSM), .display(display));

endmodule

module simple_proc_ext(clk, rst, din, bus, R0, R1, R2, R3, R4, R5, R6, R7, tick_FSM, display);
    // TODO: Declare inputs and outputs:
    input clk, rst;
    input [8:0] din;
    output [15:0] R0, R1, R2, R3, R4, R5, R6, R7; // for debugging purposes
    output [15:0] bus;
    output [3:0] tick_FSM;
    output [15:0] display;

    // instruction parameters
    parameter DISP = 3'd0, ADD = 3'd1, ADDI = 3'd2, SUB = 3'd3, MUL = 3'd4, SRL = 3'd5, SLL = 3'd6, MOVI = 3'd7;
    // multiplexer selection parameters
    parameter SEL_G = 4'd8, SEL_SIGNEXTDIN = 4'd9;
    // signal width parameters
    parameter DIN_WIDTH = 9, REG_WIDTH = 16;
    // ALU paramaters
    parameter ALU_ADD = 3'b000, ALU_SUB = 3'b001, ALU_MUL = 3'b010, ALU_SLL = 3'b011, ALU_SRL = 3'b100;
    // register parameters
    parameter IR_ID = 4'd0, A_ID = 4'd1, G_ID = 4'd2, H_ID = 4'd3;
    parameter NUM_GP_REG = 8; // 8 GP registers
    parameter NUM_SP_REG = 4; // 4 special registers (IR, A, G, H)


    // TODO: declare wires:
    wire [REG_WIDTH-1:0] r_out [NUM_GP_REG-1:0];
    wire [REG_WIDTH-1:0] A_in, G_in, A_out, G_out;
    wire [DIN_WIDTH-1:0] IR_out;
    wire [REG_WIDTH-1:0] sign_ext_din;
    wire [3:0] tick;
    assign tick_FSM = tick;
    wire [REG_WIDTH-1:0] alu_result, alu_input_a, alu_input_b;

    // parse the sections of the instruction given
    wire [2:0] op_code = IR_out[8:6];
    wire [2:0] rx = IR_out[5:3];
    wire [2:0] ry = IR_out[2:0];

    // declare control signals
    reg [NUM_GP_REG-1:0] gp_reg_write; // R0~7
    reg [NUM_SP_REG-1:0] sp_reg_write; // IR, A, G, H
    reg [3:0] bus_control; // Control what is being put on the bus from MUX
    reg [2:0] alu_op; // Control what operation the ALU is performing
    reg tick_enable = 1'b1; // Control whether the tick is enabled

    // instantiate sign extender:
    sign_extend sign_ext(.in(din), .ext(sign_ext_din));

    // TODO: instantiate General Purpose registers:
    genvar i;
    generate
        for (i = 0; i < NUM_GP_REG; i = i + 1) begin: reg_generate
            register_n #(.N(REG_WIDTH)) reg_inst(.r_in(bus), .enable(gp_reg_write[i]), .clk(clk), .Q(r_out[i]), .rst(rst));
        end
    endgenerate
    assign R0 = r_out[0];
    assign R1 = r_out[1];
    assign R2 = r_out[2];
    assign R3 = r_out[3];
    assign R4 = r_out[4];
    assign R5 = r_out[5];
    assign R6 = r_out[6];
    assign R7 = r_out[7];

    // instantiate special purpose IR
    register_n #(.N(DIN_WIDTH)) IR(.r_in(din), .enable(sp_reg_write[IR_ID]), .clk(clk), .Q(IR_out), .rst(rst));
    
    // TODO: instantiate Multiplexer:
    multiplexer multiplexer(.sel(bus_control), .R0(r_out[0]), .R1(r_out[1]), .R2(r_out[2]), .R3(r_out[3]), .R4(r_out[4]), .R5(r_out[5]), .R6(r_out[6]), .R7(r_out[7]), .G(G_out), .SignExtDin(sign_ext_din), .Bus(bus));

    // TODO: instantiate ALU:
    ALU alu(.input_a(alu_input_a), .input_b(alu_input_b), .alu_op(alu_op), .result(alu_result));
    // this allows us to not have to store inputs in registers
    assign alu_input_a = A_out;
    assign alu_input_b = bus;

    // instantiate ALU registers
    register_n A(.r_in(bus), .enable(sp_reg_write[A_ID]), .clk(clk), .Q(A_out), .rst(rst)); // for storing intermediate results
    register_n G(.r_in(alu_result), .enable(sp_reg_write[G_ID]), .clk(clk), .Q(G_out), .rst(rst)); // for storing the result of the ALU
    
    // TODO: instantiate tick counter:
    tick_FSM tick_fsm(.rst(rst), .clk(clk), .enable(tick_enable), .tick(tick));
    
    // instantiate HEX register (not used in this task)
    register_n H(.r_in(bus), .enable(sp_reg_write[H_ID]), .clk(clk), .Q(display), .rst(rst));


    // TODO: define control unit:
    always @(*) begin
        // TODO: Turn off all control signals:
        // the separation of sp and gp reg writes prevent illegral overwrites of content in non gp reg  
        sp_reg_write <= 0;
        gp_reg_write <= 0;
        alu_op <= 0;
        bus_control <= 0;
        // TODO: Turn on specific control signals based on current tick:
        case (tick)
            // tick 1
            4'b0001:
                begin
                    sp_reg_write[IR_ID] <= 1'b1; // enable IR
                end
            // tick 2
            4'b0010:
                begin
                    case (op_code) 
                        DISP:
                            begin
                                bus_control <= rx; // select the 1st register to bus
                                sp_reg_write[H_ID] <= 1'b1; // write into H
                            end
                        ADD: 
                            begin
                                bus_control <= rx; // select the 1st register to bus
                                sp_reg_write[A_ID] <= 1'b1; // write into A
                            end
                        ADDI:
                            begin
                                bus_control <= SEL_SIGNEXTDIN; // select the immediate to bus
                                sp_reg_write[A_ID] <= 1'b1; // write into A
                            end
                        SUB:
                            begin
                                bus_control <= rx; // select the immediate to bus
                                sp_reg_write[A_ID] <= 1'b1; // write into A
                            end
                        MUL:
                            begin 
                                bus_control <= rx; // select the 1st register to bus
                                sp_reg_write[A_ID] <= 1'b1; // write into A
                            end
                        SRL:
                            begin
                                bus_control <= rx; // select the 1st register to bus
                                alu_op <= ALU_SRL; // shift right
                                sp_reg_write[G_ID] <= 1'b1; // write into G
                            end
                        SLL:
                            begin
                                bus_control <= rx; // select the 1st register to bus
                                alu_op <= ALU_SLL; // shift right
                                sp_reg_write[G_ID] <= 1'b1; // write into G
                            end
                        MOVI:   
                            begin
                                bus_control <= SEL_SIGNEXTDIN; // select the immediate to bus
                                gp_reg_write[rx] <= 1'b1; // write into rx
                            end
                    endcase
                end
            // tick 3
            4'b0100:
                begin
                    case (op_code) 
                        ADD: 
                            begin
                                bus_control <= ry; // select the 2nd register to bus
                                alu_op <= ALU_ADD; // add
                                sp_reg_write[G_ID] <= 1'b1; // write into G
                            end
                        ADDI:
                            begin
                                bus_control <= rx; // select the rx to bus
                                alu_op <= ALU_ADD; // add
                                sp_reg_write[G_ID] <= 1'b1; // write into G
                            end
                        SUB:
                            begin
                                bus_control <= ry; // select the ry to bus
                                alu_op <= ALU_SUB; // subtract
                                sp_reg_write[G_ID] <= 1'b1; // write into G
                            end
                        MUL:
                            begin
                                bus_control <= ry; // select the 2nd register to bus
                                alu_op <= ALU_MUL; // multiply
                                sp_reg_write[G_ID] <= 1'b1; // write into G
                            end
                        SRL:
                            begin
                                bus_control <= SEL_G; // select G to bus
                                gp_reg_write[rx] <= 1'b1; // write into rx
                            end
                        SLL:
                            begin
                                bus_control <= SEL_G; // select G to bus
                                gp_reg_write[rx] <= 1'b1; // write into rx
                            end
                        default: begin // no operation for any other instruction 
											end
                    endcase
                end
            // tick 4
            4'b1000:
                begin
                    case (op_code) 
                        ADD: 
                            begin
                                bus_control <= SEL_G; // select G to bus
                                gp_reg_write[rx] <= 1'b1; // write into rx
                            end
                        ADDI:
                            begin
                                bus_control <= SEL_G; // select G to bus
                                gp_reg_write[rx] <= 1'b1; // write into rx
                            end
                        SUB:
                            begin
                                bus_control <= SEL_G; // select G to bus
                                gp_reg_write[rx] <= 1'b1; // write into rx
                            end
                        MUL:
                            begin
                                bus_control <= SEL_G; // select G to bus
                                gp_reg_write[rx] <= 1'b1; // write into rx
                            end
                        default: begin // no operation for any other instruction 
											end
                    endcase
                end
            default: begin // no operation for any other instruction 
                        end
        endcase

    end

endmodule
