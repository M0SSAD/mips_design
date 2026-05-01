module tb_pc_reg();

    reg clk;
    reg rst_n;
    reg [31:0] test_pc_next;

    wire [31:0] test_pc;

    pc_reg dut(
        .clk(clk),
        .rst_n(rst_n),
        .pc_next(test_pc_next),
        .pc(test_pc)
    );

    always #5 clk = ~clk;

    initial begin
        $monitor("Time: %4t | clk: %b | rst_n: %b | pc_next: %4d || pc_out: %4d", 
                 $time, clk, rst_n, test_pc_next, test_pc);
        clk= 0;
        test_pc_next = 32'b0;
        
        // Test Case 1: The Reset Condition
        rst_n = 0; 
        #10; // Wait for one full clock cycle
        
        // Release the reset (pull it HIGH) so the PC can start working
        rst_n = 1;
        #10;

        test_pc_next = test_pc_next + 4; 
        
        // Wait 10 time units for the clock to tick and the flip-flop to capture it
        #10; 

        test_pc_next = test_pc_next + 4; 
        #10;

        // Test Case 4: Asynchronous Reset Mid-Execution
        rst_n =0;
        #10;
        rst_n = 1;
        #20;
        test_pc_next = test_pc_next + 4; 
        #10;
        test_pc_next = test_pc_next + 4; 
        #10;

        $stop;
    end

endmodule