`timescale 1ns / 1ps

module tb_ram_memory();

    // 1. Inputs to DUT (Registers)
    reg clk;
    reg test_wr_en;
    reg [9:0] test_addr;
    reg [31:0] test_wr_data;

    // 2. Outputs from DUT (Wires)
    wire [31:0] test_rd_data;

    // 3. Instantiate the Device Under Test
    ram_memory dut(
        .clk(clk),
        .wr_en(test_wr_en),
        .addr(test_addr),
        .wr_data(test_wr_data),
        .rd_data(test_rd_data)
    );

    // 4. Clock Generator
    always #5 clk = ~clk; 

    // 5. Apply Stimulus
    initial begin
        // Monitor prints output in hex format (%h) to easily track the Little-Endian byte splitting
        $monitor("Time: %4t | clk: %b | wr_en: %b | addr: %4d | wr_data: %h || rd_data: %h", 
                 $time, clk, test_wr_en, test_addr, test_wr_data, test_rd_data);

        // INITIALIZATION
        clk = 0;
        test_wr_en = 0;
        test_addr = 0;
        test_wr_data = 32'h0;
        #10; 

        // Test Case 1: Write to Address 0
        test_addr = 0;
        test_wr_data = 32'hAABBCCDD; 
        test_wr_en = 1;      // Enable writing
        #10;                 // Wait for the posedge clock to capture the data

        // Test Case 2: Read from Address 0
        test_wr_en = 0;      // Turn OFF write enable to prevent accidental overwrites
        #10;                 // Advance time to observe the read data

        // Test Case 3: Write to Address 4
        test_addr = 4;
        test_wr_data = 32'h11223344; 
        test_wr_en = 1;      // Enable writing
        #10;                 // Wait for the posedge clock to capture the data

        // Test Case 4: Read from Address 4
        test_wr_en = 0;      // Turn OFF write enable to prevent accidental overwrites
        #10;                 // Advance time to observe the read data

        // Test Case 5: The Write Protect Test
        test_addr = 8;
        test_wr_data = 32'hFFFFFFFF; 
        #10;
        #10;

        $stop;
    end

endmodule