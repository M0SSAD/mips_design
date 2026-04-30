module ram_memory #(parameter depth = 1024, parameter width = 8) (
    input clk, input wr_en,
    input [$clog2(depth) - 1: 0] addr,
    input [4*(width) - 1: 0] wr_data,

    output [4*(width) - 1: 0] rd_data
);

reg [width - 1: 0] mem [0: depth - 1];
integer i;
initial begin
    for(i = 0; i < depth; i = i + 1) begin
        mem[i] <= 8'b0;
    end
end
always @(posedge(clk)) begin
    if(wr_en) begin
        {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= wr_data;
    end
end

assign rd_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};

endmodule