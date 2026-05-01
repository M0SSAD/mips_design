module tb_rf();

    reg clk;
    reg test_WE3;
    reg [4:0] test_A1;
    reg [4:0] test_A2;
    reg [4:0] test_A3;
    reg [31:0] test_WD3;

    wire [31:0] test_RD1;
    wire [31:0] test_RD2;
    wire [3:0] test_s0_reg;

    rf dut(
        .clk(clk),
        .WE3(test_WE3),
        .A1(test_A1),
        .A2(test_A2),
        .A3(test_A3),
        .WD3(test_WD3),
        .RD1(test_RD1),
        .RD2(test_RD2),
        .s0_reg(test_s0_reg)
    );

    always #5 clk = ~clk;

    // Apply Stimulus
    initial begin
        $monitor("Time: %4t | WE3: %b | Wr_Addr: %2d | Wr_Data: %4d || Rd_Addr: %2d -> RD1: %4d, Rd_Addr: %2d -> RD2: %4d", 
                $time, test_WE3, test_A3, test_WD3, test_A1, test_RD1, test_A2, test_RD2);

        // INITIALIZATION
        clk = 0;
        test_WE3 = 0;
        test_A1 = 0;
        test_A2 = 0;
        test_A3 = 0;
        test_WD3 = 0;
        #10; 

        // Test Case 1: Write to Register 5
        test_A3 = 5;         // Destination register
        test_WD3 = 32'd100;  // Data to write
        test_WE3 = 1;        // Enable writing
        #10;                 // Wait for the posedge clock to capture it
        
        test_WE3 = 0;        // Turn OFF write

        // Test Case 2: Read from Register 5
        test_A1 = 5;         // Ask port 1 to look at register 5
        #10;                 // The data (100) should appear on test_RD1

        // Test Case 3: The Register 0 Hardwire Rule
        test_A3 = 0;         // Destination register
        test_WD3 = 32'd999;  // Data to write
        test_WE3 = 1;        // Enable writing
        #10;                 // Wait for the posedge clock to capture it
        test_WE3 = 0;        // Turn OFF write
        test_A1 = 0;        
        #10;                

        // Test Case 4: Dual Read
        test_A3 = 8;         // Destination register
        test_WD3 = 32'd42;  // Data to write
        test_WE3 = 1;        // Enable writing
        #10;                 // Wait for the posedge clock to capture it
        test_A3 = 9;         // Destination register
        test_WD3 = 32'd77;  // Data to write
        #10;
        test_WE3 = 0;  
        test_A1 = 8;
        test_A2 = 9;

        #10;
        $stop;
    end

endmodule