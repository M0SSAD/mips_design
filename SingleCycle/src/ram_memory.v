module ram_memory #(parameter depth = 1024, parameter width = 8) (
    input clk, 
    input [3:0] byte_en,
    input [$clog2(depth) - 1: 0] addr,
    input [31:0] wr_data,
    output wire [31:0] rd_data
);
    reg [width - 1: 0] mem [0: depth - 1];

    always @(posedge clk) begin
        // Independent byte-lane writes
        if(byte_en[0]) mem[addr]   <= wr_data[7:0];
        if(byte_en[1]) mem[addr+1] <= wr_data[15:8];
        if(byte_en[2]) mem[addr+2] <= wr_data[23:16];
        if(byte_en[3]) mem[addr+3] <= wr_data[31:24];
    end

    assign rd_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
endmodule