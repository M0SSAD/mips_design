// this memory is byte addressable, each address is of 8 bits, and it has 2^10 addresses.
// 1 KB of memory.
module ram_memory #(parameter depth = 1024, parameter width = 8) (
    input clk, input wr_en,
    input [$clog2(depth) - 1: 0] addr,
    input [4*(width) - 1: 0] wr_data,

    output wire [4*(width) - 1: 0] rd_data
);

reg [width - 1: 0] mem [0: depth - 1];
integer i;
// initialize the memory with 0 values.
initial begin
    for(i = 0; i < depth; i = i + 1) begin
        mem[i] <= 8'b0;
    end
end
// write the data at each positive edge if write was enabled.
always @(posedge(clk)) begin
    if(wr_en) begin
        {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= wr_data;
    end
end

// read data without a clock
assign rd_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};

endmodule