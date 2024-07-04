`timescale 1ns/1ns

// #1000 between each test
module components_tb;
    //sign extender
    integer sign_counter; // 4 cases are tested
    integer sign_errors;
    reg signed [15:0] true_sign_out;
    reg signed [8:0] sign_ext_in;
    wire signed [15:0] sign_ext_out;
    sign_extend sign_ext(.in(sign_ext_in), .ext(sign_ext_out));

    // for conclusion
    integer total_error;

    // tick FSM (share clock with register)
    integer tick_counter;
    integer tick_errors;
    reg clk, rst, enable;
    reg [3:0] right_tick;
    wire [3:0] tick;
    tick_FSM tick_fsm(.rst(rst), .clk(clk), .enable(enable), .tick(tick));

    // multiplexer
    reg [3:0] mux_counter;
    integer mux_errors;
    reg [3:0] mux_sel;
    wire [15:0] mux_out;
    multiplexer mux(.SignExtDin(16'd9), .R0(16'd0), .R1(16'd1), .R2(16'd2), .R3(16'd3), .R4(16'd4), .R5(16'd5), .R6(16'd6), .R7(16'd7), .G(16'd8), .sel(mux_sel), .Bus(mux_out));

    // ALU
    integer alu_counter;
    integer alu_errors;
    reg signed [15:0] alu_a, alu_b;
    reg [2:0] alu_op, op_iter;
    reg signed [15:0] true_alu_out;
    wire signed [15:0] alu_result;
    ALU alu(.input_a(alu_a), .input_b(alu_b), .alu_op(alu_op), .result(alu_result));

    // register
    integer reg16_counter;
    integer reg9_counter;
    integer reg_error;
    reg [0:0] reg_clk;
    reg [15:0] reg16_in;
    wire [15:0] reg16_out;
    reg [0:0]reg16_enable;
    reg [0:0] reg16_rst;
    register_n #(.N(16)) reg16(.r_in(reg16_in), .Q(reg16_out), .enable(reg16_enable), .rst(reg16_rst), .clk(reg_clk));
    reg [8:0] reg9_in;
    wire [8:0] reg9_out;
    reg [0:0] reg9_enable;
    reg [0:0] reg9_rst;
    register_n #(.N(9)) reg9(.r_in(reg9_in), .Q(reg9_out), .enable(reg9_enable), .rst(reg9_rst), .clk(reg_clk));
    
    task sign_ext_test;
        begin
            true_sign_out = sign_ext_in;
            if (true_sign_out != sign_ext_out) begin
                sign_errors = sign_errors + 1;
                $display("Sign extender test failed for input %b, expected %b, got %b", sign_ext_in, true_sign_out, sign_ext_out);
            end
        end
    endtask

    task alu_op_test;
        begin
            for (op_iter=3'b000; op_iter<=3'b100; op_iter=op_iter+1) begin
                alu_op = op_iter;
                #10;
                case(alu_op)
                    3'b000: true_alu_out = alu_a + alu_b;
                    3'b001: true_alu_out = alu_a - alu_b;
                    3'b010: true_alu_out = alu_a * alu_b;
                    3'b011: true_alu_out = alu_b << 1;
                    3'b100: true_alu_out = alu_b >> 1;
                    default: true_alu_out = 16'd0;
                endcase
                if (true_alu_out != alu_result) begin
                    alu_errors = alu_errors + 1;
                    $display("ALU test failed for input pair (%d, %d), op_code %b, expected %d, got %d", alu_a, alu_b, alu_op, true_alu_out, alu_result);
                end
            end
        end
    endtask

    // testing sign extender
    always begin
        total_error = 0;

        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Testing sign extender");
        sign_errors = 0;
    // test sign extender, 4 cases, 1 positive, 1 negative, all 0 & all 1
        for (sign_counter=0; sign_counter<4; sign_counter=sign_counter+1) begin
            case(sign_counter)
                2'd0:
                    sign_ext_in = 9'sd0;
                2'd1:
                    sign_ext_in = 9'sb111111111;
                2'd2:
                    sign_ext_in = -9'sd59;
                2'd3:
                    sign_ext_in = 9'sd38;
            endcase
            sign_ext_test();
        end
        if (sign_errors == 0) begin
            $display("Sign extender test passed");
        end
        else begin
            $display("Sign extender test failed with %d errors", sign_errors);
        end
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        total_error = total_error + sign_errors;

        // test tick_FSM
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Testing tick_FSM");
        tick_errors = 0;
        // test tick FSM 10 ticks including some resets and enable
        clk = 0;
        enable = 0;
        rst = 0;
        right_tick = 4'b0001;
        // 2 ticks with no enable, expect 0001
        for(tick_counter=0; tick_counter<2; tick_counter=tick_counter+1) begin
            #10
            clk = 1; // posedge
            #10
            if (tick != right_tick) begin
                $display("Tick FSM enable test failed, expected %b, got %b", right_tick, tick);
                tick_errors = tick_errors + 1;
            end
            clk = 0;
        end
        #10
        clk = 0;
        enable = 1;
        rst = 0;
        right_tick = 4'b0001;
        // 2 ticks with no enable, expect 0001
        for(tick_counter=0; tick_counter<6; tick_counter=tick_counter+1) begin
            #10
            clk = 1; // posedge
            // update tick by logic
            case (right_tick) 
                    4'b0001: right_tick = 4'b0010;
                    4'b0010: right_tick = 4'b0100;
                    4'b0100: right_tick = 4'b1000;
                    4'b1000: right_tick = 4'b0001;
                endcase
            #10
            if (tick != right_tick) begin
                $display("Tick FSM tick test failed, expected %b, got %b", right_tick, tick);
                tick_errors = tick_errors + 1;
            end
            clk = 0;
        end
        #10
        clk = 0;
        enable = 1;
        rst = 1;
        right_tick = 4'b0001;
        // 2 ticks with rst, expect 0001
        for(tick_counter=0; tick_counter<2; tick_counter=tick_counter+1) begin
            #10
            clk = 1; // posedge
            #10
            if (tick != right_tick) begin
                $display("Tick FSM reset test failed, expected %b, got %b", right_tick, tick);
                tick_errors = tick_errors + 1;
            end
            clk = 0;
        end
        if (tick_errors == 0) begin
            $display("Tick FSM test passed");
        end
        else begin
            $display("Tick FSM test failed with %d errors", tick_errors);
        end
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        total_error = total_error + tick_errors;

    // test multiplexer
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Testing multiplexer");
        mux_errors = 0;
        for(mux_counter=4'd0; mux_counter<=4'd9; mux_counter=mux_counter+1) begin
            mux_sel = mux_counter;
            #10;
            if (mux_out != mux_counter) begin
                $display("Multiplexer test failed, expected val in R%d, got %d (R8 is G, R9 is din)", mux_counter, mux_out);
                mux_errors = mux_errors + 1;
            end
        end
        if (mux_errors == 0) begin
            $display("Multiplexer test passed");
        end
        else begin
            $display("Multiplexer test failed with %d errors", mux_errors);
        end
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        total_error = total_error + mux_errors;

    // test ALU
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Testing ALU");
        alu_errors = 0;
        // test ALU add
        alu_op = 3'b000;
        alu_a = 16'd0;
        alu_b = 16'd0;
        alu_counter = 0;
        for (alu_counter=0; alu_counter<5; alu_counter=alu_counter+1) begin
            // test 5 cases, ++, --, +-, -+, 0
            case(alu_counter)
                4'd0:
                    begin
                        alu_a = 16'sd11;
                        alu_b = 16'sd227;
                    end
                4'd1:
                    begin
                        alu_a = -16'sd29;
                        alu_b = -16'sd431;
                    end
                4'd2:
                    begin
                        alu_a = 16'sd123;
                        alu_b = -16'sd321;
                    end
                4'd3:
                    begin
                        alu_a = -16'sd213;
                        alu_b = 16'sd445;
                    end
                4'd4:
                    begin
                        alu_a = 16'sd0;
                        alu_b = 16'sd0;
                    end
                
            endcase
            #10
            alu_op_test();
        end
        if (alu_errors == 0) begin
            $display("ALU test passed");
        end
        else begin
            $display("ALU failed with %d errors", alu_errors);
        end
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        total_error = total_error + alu_errors;

    // test register
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Testing register");
        // test 16 bit register
        reg_error = 0;
        reg16_rst = 1'b0;
        reg16_enable = 1'b1;
        reg16_in = 16'd0;
        reg_clk = 0;
        for (reg16_counter=0; reg16_counter<5; reg16_counter=reg16_counter+1) begin
            case(reg16_counter) 
                0:
                    reg16_in = 16'd0;
                1:
                    reg16_in = 16'd1;
                2:
                    reg16_in = 16'd2;
                3:
                    reg16_in = 16'd3;
                4:
                    reg16_in = 16'd4;
            endcase
            reg16_enable = 1'b1;
            #10;
            reg_clk = 1;
            #10;
            if (reg16_out != reg16_in) begin
                reg_error = reg_error + 1;
                $display("16 bit register write test failed, expected %d, got %d", reg16_in, reg16_out);
            end
            #10
            reg_clk = 0;
            reg16_rst = 1'b1;
            reg16_enable = 1'b0;
            #10
            reg_clk = 1;
            #10;
            if (reg16_out != 16'd0) begin
                reg_error = reg_error + 1;
                $display("16 bit register reset test failed, expected 0, got %d", reg16_out);
            end
            reg_clk = 0;
            reg16_rst = 1'b0;
        end
        // test 9 bit register
        reg9_rst = 1'b0;
        reg9_enable = 1'b0;
        reg9_in = 9'd0;
        reg_clk = 0;
        for (reg9_counter=0; reg9_counter<5; reg9_counter=reg9_counter+1) begin
            case(reg9_counter) 
                0:
                    reg9_in = 9'd0;
                1:
                    reg9_in = 9'd1;
                2:
                    reg9_in = 9'd2;
                3:
                    reg9_in = 9'd3;
                4:
                    reg9_in = 9'd4;
                
            endcase
            reg9_enable = 1'b1;
            #10
            reg_clk = 1;
            #10
            if (reg9_out != reg9_in) begin
                reg_error = reg_error + 1;
                $display("9 bit register write test failed, expected %d, got %d", reg9_in, reg9_out);
            end
            #10
            reg_clk = 0;
            reg9_rst = 1'b1;
            reg9_enable = 1'b0;
            
            #10
            reg_clk = 1;
            #10;
            if (reg9_out != 9'd0) begin
                reg_error = reg_error + 1;
                $display("9 bit register reset test failed, expected 0, got %d", reg9_out);
            end
            reg_clk = 0;
            reg9_rst = 1'b0;
        end
        if (reg_error == 0) begin
            $display("Register test passed");
        end
        else begin
            $display("Register test failed with %d errors", reg_error);
        end
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        total_error = total_error + reg_error;
        $display("The tests have ended");
        if (total_error == 0) begin
            $display("All tests passed");
        end
        else begin
            $display("Some tests failed with %d errors", total_error);
        end


        $stop;
    end

endmodule

