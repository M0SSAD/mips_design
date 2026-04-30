module rf (
    input clk, WE3,
    input [4:0] A1, A2, A3,
    input [31:0] WD3,

    output [31:0] RD1, RD2,
    output [3:0] s0_reg
);

reg [31:0] register_file [0:31];

assign RD1 = (A1 != 5'b0) ? register_file[A1] : 32'b0;
assign RD2 = (A2 != 5'b0) ? register_file[A2] : 32'b0;

assign s0_reg = register_file[16][3:0];

always @(posedge clk) begin
    if(WE3) begin
        register_file[A3] <= WD3;
    end
end

endmodule