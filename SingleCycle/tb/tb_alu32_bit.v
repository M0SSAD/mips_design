module tb_alu32_bit();

    // 1. Inputs to DUT (Registers)
     reg signed [31:0] test_srcA;
     reg signed [31:0] test_srcB;
     reg [2:0] test_ALU_control;

    // 2. Outputs from DUT (Wires)
     wire [31:0] test_alu_out;
     wire test_zero_flg;
     wire test_gt;
     wire test_lt;

    // 3. Instantiate the Device Under Test
    alu32_bit dut(
        .srcA(test_srcA),
        .srcB(test_srcB),
        .ALU_control(test_ALU_control),
        .alu_out(test_alu_out),
        .zero_flg(test_zero_flg),
        .gt(test_gt),
        .lt(test_lt)
    );

    // 4. Apply Stimulus
    initial begin
        // The $monitor automatically prints to the console whenever ANY of these variables change
        $monitor("Time: %4t | srcA: %4d | srcB: %4d | ctrl: %b || out_d: %4d | out_b: %b | zero: %b", 
                 $time, test_srcA, test_srcB, test_ALU_control, test_alu_out, test_alu_out, test_zero_flg);

        // Test Case 1: ADD (ALU_control = 010)
        test_srcA = 15;
        test_srcB = 10;
        test_ALU_control = 3'b010; 
        #10; // Wait 10 time units for logic to propagate

        // Test Case 2: SUB (ALU_control = 110)
        test_ALU_control = 3'b110;
        #10;

        // zero_flag
        test_srcA = 15;
        test_srcB = 15;
        test_ALU_control = 3'b110;
        #10;

        // Test Case 3: SLT (ALU_control = 111)
        test_srcA = 10;
        test_srcB = 12;
        test_ALU_control = 3'b111;
        #10;


        // Test Case 4: AND / OR
        test_ALU_control = 3'b000;
        #10;
        test_ALU_control = 3'b001;
        #10;


        $end; // Pause the simulation when finished
    end

endmodule