`timescale 1ns/1ns

module proc_tb;
    // parameter definitions
    parameter ADD = 3'd1, ADDI = 3'd2, SUB = 3'd3, MOVI = 3'd7;
    // constants for clarity
    parameter DONT_CARE_REG = 3'bxxx, DONT_CARE_IMMI = 9'bxxxxxxxxx, TRUE = 1'b1, FALSE = 1'b0;

    // error counting
    integer total_error;

    // mostly fixed inputs
    reg rst;
    reg [0:0] clk;
    // input
    reg [8:0] din;
    // outputs
    wire [15:0] reg_values [7:0]; // R0~7
    wire [15:0] bus;
    wire [3:0] tick_FSM;
    wire [3:0] bus_control;
    // processor
    simple_proc proc(.clk(clk), .rst(rst), .din(din), .bus(bus), 
                    .R0(reg_values[0]), .R1(reg_values[1]), .R2(reg_values[2]), 
                    .R3(reg_values[3]), .R4(reg_values[4]), .R5(reg_values[5]), 
                    .R6(reg_values[6]), .R7(reg_values[7]), .tick_FSM(tick_FSM), .bus_control(bus_control));
    
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
    reg [15:0] reg_values_before [7:0];
    reg [15:0] bus_values_by_tick [3:0];
	integer i;
    initial begin
		for (i = 0; i < 4; i = i + 1) begin
            bus_values_by_tick[i] = 16'd0;
		end
		for (i = 0; i <= 7; i = i + 1) begin
            reg_values_before[i] = 16'd0;
		end
    end

    parameter A = 1664525;
    parameter C = 1013904223;
    integer rand_num = 108;
    task gen_rand_immi;
        begin
            for (i = 0; i <= 3; i = i + 1) begin
                rand_num = A * rand_num + C; // mod 2^9
                rand_immi[i] = rand_num[8:0];
            end
        end
    endtask

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
            for (i = 0; i <= 7; i = i + 1) begin
                $display("r%01d     %05d", i, reg_values_before[i]);
            end
            $display("after instruction:");
            $display("register   value");
            for (i = 0; i <= 7; i = i + 1) begin
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
            for (i = 0; i <= 7; i = i + 1) begin
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
    
    always begin
        #2;
        $display("Bus values during execution and register values before and after will be printed if error occurs. \n Exmaple below: ");
        print_bus_values();
        print_register_values();
        #3; // match the initial delay
        
        #2; // dummy delay for instruction to start
        rst = FALSE; // turn reset off to start
        #3

        // test movi
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "movi");
        error_count = 0;
        /*
        Test movi instruction with positive numbers
        r0 = 10
        */
        movi(3'd0, 9'd10);
        test_error(4'd0, 16'd10);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "movi-pos", "r0 should be 10"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "movi-pos");
        end
        
        /*
        Test movi instruction with negative numbers
        r1 = -10
        */
        movi(3'd1, -9'sd10);
        test_error(4'd1, -16'sd10);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "movi-neg", "r1 should be -10"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "movi-neg");
        end
        $display("Test movi completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        
        // test add
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "add");
        error_count = 0;
        /*
        Test add instruction with positive numbers
        r2 = 10
        r3 = 20
        r2 = r2+r3
        */
        movi(3'd2, 9'd10);
        movi(3'd3, 9'd20);
        add(3'd2, 3'd3);
        test_error(4'd2, 16'd30);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "add-pos", "r2 should be 30"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "add-pos");
        end

        /*
        Test add instruction with negative numbers
        r4 = -108
        r5 = -20
        r4 = r4+r5
        */
        movi(3'd4, -9'sd108);
        movi(3'd5, -9'sd20);
        add(3'd4, 3'd5);
        test_error(4'd4, -16'sd128);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "add-neg", "r2 should be -88"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "add-neg");
        end
        $display("Test add completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        // test addi
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "addi");
        error_count = 0;
        /*
        Test addi instruction with positive numbers
        r6 = 10
        r6 = r6+20
        */
        movi(3'd6, 9'd10);
        addi(3'd6, 9'd20);
        test_error(4'd6, 16'd30);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "addi-pos", "r6 should be 30"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "addi-pos");
        end

        /*
        Test addi instruction with negative numbers
        r7 = 10
        r7 = r7-20
        */
        movi(3'd7, 9'd10);
        addi(3'd7, -9'sd20);
        test_error(4'd7, -16'sd10);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "addi-neg", "r7 should be -10"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "addi-neg");
        end
        $display("Test addi completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        // test sub
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "sub");
        error_count = 0;
        /*
        Test sub instruction with positive numbers
        r0 = 10
        r1 = 20
        r0 = r0-r1
        */
        movi(3'd0, 9'd10);
        movi(3'd1, 9'd20);
        sub(3'd0, 3'd1);
        test_error(4'd0, -16'sd10);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "sub-pos", "r0 should be -10"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "sub-pos");
        end

        /*
        Test sub instruction with negative numbers
        r2 = -10
        r3 = -20
        r2 = r2-r3
        */
        movi(3'd2, -9'sd10);
        movi(3'd3, -9'sd20);
        sub(3'd2, 3'd3);
        test_error(4'd2, 16'sd10);
        if (success!=TRUE) begin 
            $display("Test \<%s\> failed. %s", "sub-neg", "r2 should be 10"); 
        end else begin
            $display("Test \<%s\> succeeded. ", "sub-neg");
        end
        $display("Test sub completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        // test complicated
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("Tests for %s", "complicated");
        error_count = 0;
        complicated_test_count = 0;
        /*
        Test complicated instruction (use all 4 available) 20 times
        Do         ((r0-immi)<-addi+(r2-r3)<-sub)<-add
        */
        for (complicated_test_count=1; complicated_test_count<20; complicated_test_count=complicated_test_count+1) begin
            gen_rand_immi();
            movi(3'd0, rand_immi[0]);
            movi(3'd2, rand_immi[1]);
            movi(3'd3, rand_immi[2]);
            // see if a movi is done, if not, then errors after may not be useful
            test_error(4'd0, rand_immi[0]);
            if (success!=TRUE) begin 
                $display("Test \<%s\> failed. %s%05d", "complicated-1-interim_movi", "r0 should be ", rand_immi[0]); 
            end else begin
                $display("Test \<%s\> succeeded. ", "complicated-1-interim_movi");
            end
            // r0 = r0-rand
            addi(3'd0, rand_immi[3]);
            // r2 = r2-r3
            sub(3'd2, 3'd3);
            // r0 = r0+r2
            add(3'd0, 3'd2);
            test_error(4'd0, (rand_immi[0]+rand_immi[3])+(rand_immi[1]-rand_immi[2]));
            if (success!=TRUE) begin 
                $display("Test \<%s%02d\> failed. %s %05d", "complicated-", complicated_test_count, "r0 should be ", (rand_immi[0]+rand_immi[3])+(rand_immi[1]-rand_immi[2])); 
            end else begin
                $display("Test \<%s%02d\> succeeded. ", "complicated-", complicated_test_count);
            end
        end 
        $display("Test complicated completed with %d errors", error_count);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

        $display("Tests have all finished. ")
        if (total_error == 0) begin
            $display("All tests passed!");
        end else begin
            $display("There are %d errors in total.", total_error);
        end

		$stop;
    end


endmodule