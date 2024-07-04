`timescale 1ns/1ns

module proc_extension_tb;
    // parameter definitions
    // opcode
    parameter DISP = 3'd0, ADD = 3'd1, ADDI = 3'd2, SUB = 3'd3, MUL = 3'd4, SRL = 3'd5, SLL = 3'd6, MOVI = 3'd7;
    // constants for clarity
    parameter DONT_CARE_REG = 3'bxxx, DONT_CARE_IMMI = 9'bxxxxxxxxx, TRUE = 1'b1, FALSE = 1'b0;

    // for conclusion and error counting
    integer total_error = 0;

    // mostly fixed inputs
    reg rst;
    reg clk;
    // input
    reg [8:0] din;
    // outputs
    wire [15:0] reg_values [8:0]; // 9th reg as display i.e. reg_values[8]
    integer sll_shift_loop_var;
    wire [15:0] bus;
    wire [3:0] tick_FSM;
    // processor
    simple_proc_ext proc(.clk(clk), .rst(rst), .din(din), .bus(bus), 
                    .R0(reg_values[0]), .R1(reg_values[1]), .R2(reg_values[2]), 
                    .R3(reg_values[3]), .R4(reg_values[4]), .R5(reg_values[5]), 
                    .R6(reg_values[6]), .R7(reg_values[7]), .tick_FSM(tick_FSM), .display(reg_values[8]));
	  reg signed [8:0] rand_immi [3:0];
    integer complicated_test_count;
	 
    // init
    initial begin
        clk <= 0;
        rst <= 1;
        din <= 0;
        total_error <= 0;
    end

    // clock at 10ns, note the initial #5 delay to start (5, 10, 15 posedges)
    always begin
        #5
        if (clk == TRUE) begin
            clk = FALSE;
        end else begin
            clk = TRUE;
        end
    end

    // testbench params
	 integer i;
    reg [15:0] reg_values_before [8:0];
    reg [15:0] bus_values_by_tick [3:0];
    initial begin
		for (i = 0; i < 4; i = i + 1) begin
          bus_values_by_tick[i] = 16'd0;
		end
		for (i = 0; i <= 8; i = i + 1) begin
			 reg_values_before[i] = 16'd0;
		end
    end
     
    // print bus values during the last instruction execution
    task print_bus_values;
        begin
            $display("tick    bus_value");
            // replce eith for loop
            for (i = 0; i < 4; i = i + 1) begin
                $display("%01d   %05d", i, bus_values_by_tick[i]);
            end
        end
    endtask

    // print last saved register value and current register value
    task print_register_values;
        begin
            $display("before instruction:");
            $display("register   value");
            for (i = 0; i <= 8; i = i + 1) begin
                $display("r%01d     %05d", i, reg_values_before[i]);
            end
            $display("after instruction:");
            $display("register   value");
            for (i = 0; i <= 8; i = i + 1) begin
                $display("r%01d     %05d", i, reg_values[i]);
            end
        end
    endtask

    // basic instruction template, #100 delay
    task instruction;
        input [2:0] op_code;
        input [2:0] rx;
        input [2:0] ry;
        input [8:0] immediate;
        input [0:0] has_immediate;
        begin
            for (i = 0; i <= 8; i = i + 1) begin
                reg_values_before[i] = reg_values[i];
            end

            // note that tick 1 only has #5 delay, to match the additional delays at the end of each instruction
            // tick 1 starts
            din = {op_code, rx, ry};
            bus_values_by_tick[0] = bus;
            #5;
            // tick 2
            #5;
            if (has_immediate == TRUE) din = immediate;
            bus_values_by_tick[1] = bus;
            #5;
            
            // no input change ever occurs in tick 3 and 4
            // tick 3
            #5;
            bus_values_by_tick[2] = bus;
            #5;
            // tick 4
            #5;
            bus_values_by_tick[3] = bus;
            #5;

            // next round tick 1 to make sure update goes through
            din = 0; // clear input so that last instruction does not affect next instruction
            #5;
        end
    endtask

    task disp;
        input [2:0] rx;
        begin
            instruction(DISP, rx, DONT_CARE_REG, DONT_CARE_IMMI, FALSE);
        end
    endtask

    task add;
        input [2:0] rx, ry;
        begin
            instruction(ADD, rx, ry, DONT_CARE_IMMI, FALSE);
        end
    endtask

    task addi;
        input [2:0] rx;
        input [8:0] immediate;
        begin
            instruction(ADDI, rx, DONT_CARE_REG, immediate, TRUE);
        end 
    endtask

    task sub;
        input [2:0] rx, ry;
        begin
            instruction(SUB, rx, ry, DONT_CARE_IMMI, FALSE);
        end
    endtask

    task mul;
        input [2:0] rx, ry;
        begin
            instruction(MUL, rx, ry, DONT_CARE_IMMI, FALSE);
        end
    endtask

    task sll;
        input [2:0] rx;
        begin
            instruction(SLL, rx, DONT_CARE_REG, DONT_CARE_IMMI, FALSE);
        end
    endtask

    task srl;
        input [2:0] rx;
        begin
            instruction(SRL, rx, DONT_CARE_REG, DONT_CARE_IMMI, FALSE);
        end
    endtask

    task movi;
        input [2:0] rx;
        input [8:0] immediate;
        instruction(MOVI, rx, DONT_CARE_REG, immediate, TRUE);
    endtask


    reg [0:0] success;
    integer error_count;
    task test_error;
        input [2:0] reg_modified;
        input [15:0] expected_value;
        begin
            if (reg_values[reg_modified] != expected_value) begin
                error_count = error_count + 1;
                print_debug_values();
                success = FALSE;
                total_error = total_error + 1;
            end else begin
                success = TRUE;
            end
        end
    endtask

    task print_debug_values;
        begin
            print_bus_values();
            print_register_values();
        end
    endtask

    /**********************
        ACTUAL TESTING
    **********************/
    
    initial begin
        #2;
        $display("Bus values during execution and register values before and after will be printed if error occurs. \n Exmaple below: ");
        $display("tick    bus_value");
        // replce eith for loop
        for (i = 0; i < 4; i = i + 1) begin
            $display("%01d   %05d", i, bus_values_by_tick[i]);
        end
        $display("before instruction:");
        $display("register   value");
        for (i = 0; i <= 8; i = i + 1) begin
            $display("r%01d     %05d", i, reg_values_before[i]);
        end
        $display("after instruction:");
        $display("register   value");
        for (i = 0; i <= 8; i = i + 1) begin
            $display("r%01d     %05d", i, reg_values[i]);
        end
        #3; // match the initial delay

        #2; // dummy delay for instruction to start
        rst = FALSE;
        #3;
        
        // test disp
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "disp");
        error_count = 0;
        /*
        Test disp instruction
        r0 = 10
        */
        movi(3'd0, 9'd10);
        disp(3'd0);
        test_error(4'd0, 16'd10);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "disp", "r0 should be 10"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "disp");
        end
        $display("Test disp completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        // test mul
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for mul");
        error_count = 0;
        /*
        Test mul instruction with pos
        r0 = 15*15
        */
        movi(3'd0, 9'd15);
        mul(3'd0, 3'd0);
        test_error(4'd0, 16'd225);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "mul-pos", "r0 should be 225"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "mul-pos");
        end

        /*
        Test mul instruction with pos and neg
        r1 = -10*20
        */
        movi(3'd0, -9'sd10);
        movi(3'd1, 9'd20);
        mul(3'd1, 3'd0);
        test_error(4'd1, -16'sd200);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "mul-pos_neg", "r1 should be 200"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "mul-pos_neg");
        end
        
        /*
        Test mul instruction with neg
        r3 = -30*-33
        */
        movi(3'd2, -9'sd30);
        movi(3'd3, -9'sd33);
        mul(3'd3, 3'd2);
        test_error(4'd3, 16'd990);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "mul-neg", "r3 should be 990"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "mul-neg");
        end

        /*
        Test mul instruction with overflow
        r4 = -30*-33
        */
        movi(3'd4, 9'sd255);
        mul(3'd4, 3'd4);
        mul(3'd4, 3'd4);
        test_error(4'd3, 16'd990);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "mul-neg", "r3 should be 990"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "mul-neg");
        end

        /*
        Test mul instruction with 0
        r3 = 156*0
        */
        movi(3'd2, 9'd156);
        movi(3'd3, 9'd0);
        mul(3'd3, 3'd2);
        test_error(4'd3, 16'd0);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "mul-0", "r3 should be 0"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "mul-0");
        end
        $display("Test mul completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        // test sll
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "sll");
        error_count = 0;
        /*
        Test sll instruction with pos
        r0 = 10<<1
        */
        movi(3'd0, 9'd10);
        sll(3'd0);
        test_error(4'd0, 16'd20);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "sll-pos", "r0 should be 20"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "sll-pos");
        end

        /*
        Test sll instruction with neg
        r1 = -10<<1
        */
        movi(3'd0, -9'sd10);
        sll(3'd0);
        test_error(4'd0, -16'sd20);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "sll-neg", "r0 should be -20"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "sll-neg");
        end

        /*
        Test sll instruction with overflow number
        r1 = 1 << 16 = 0 (as it overflows)
        */
        movi(3'd0, 16'd1);
        // shift 16 times
        for (sll_shift_loop_var=0; sll_shift_loop_var<16; sll_shift_loop_var=sll_shift_loop_var+1) begin
            sll(3'd0);
        end
        test_error(4'd0, 16'd0);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "sll-overflow", "r0 should be 0"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "sll-overflow");
        end

        /*
        Test sll instruction with 0
        r2 = 0<<1
        */
        movi(3'd0, 9'd0);
        sll(3'd0);
        test_error(4'd0, 16'd0);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "sll-0", "r0 should be 0"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "sll-0");
        end
        $display("Test sll completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        // test srl
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "srl");
        error_count = 0;
        /*
        Test srl instruction with pos even
        r0 = 10>>1
        */
        movi(3'd0, 9'd10);
        srl(3'd0);
        test_error(4'd0, 16'd5);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "srl-pos_even", "r0 should be 5"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "srl-pos_even");
        end

        /*
        Test srl instruction with pos odd
        r1 = 11>>1
        */
        movi(3'd0, 9'd11);
        srl(3'd0);
        test_error(4'd0, 16'd5);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "srl-pos_odd", "r0 should be 5"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "srl-pos_odd");
        end

        /*
        Test srl instruction with neg
        r2 = -123>>1
           = 1111111110000101 >> 1
           = 0111111111000010 (is right shifted logically, not arithmetrically)
           = 32706
        */
        movi(3'd0, -9'sd123);
        srl(3'd0);
        test_error(4'd0, 16'd32706);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "srl-neg (neg becomes pos)", "r0 should be 32706"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "srl-neg (neg becomes pos)");
        end

        /*
        Test srl instruction with 0
        r3 = 0>>1
        */
        movi(3'd0, 9'd0);
        srl(3'd0);
        test_error(4'd0, 16'd0);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "srl-0", "r0 should be 0"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "srl-0");
        end
        $display("Test srl completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        // test complicated
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "complicated");
        error_count = 0;
        /*
        Test complicated instruction (use all 4 available)
        Calculate disp((11//2)*(103*2)) = 5*206 = 1030
        */
        movi(3'd0, 9'd11); // r0 = 11
        movi(3'd2, 9'd103); // r2 = 103
        sll(3'd2); // r2 = 103*2 = 206
        srl(3'd0); // r0 = 11//2 = 5
        mul(3'd0, 3'd2); // r2 = 5*206 = 1030
        disp(3'd0); // disp(r2)
        test_error(4'd8, 16'd1030); // r8 is display
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "complicated-ext_alone", "display should be 1030"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "complicated-ext_alone");
        end
        $display("Test complicated completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        $display("All tests are finished");
        if (total_error == 0) begin
            $display("All tests passed!");
        end else begin
            $display("Total %d errors", total_error);
        end

        $stop;
    end


endmodule