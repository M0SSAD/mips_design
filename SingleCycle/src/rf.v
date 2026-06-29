module rf (
    input clk, WE3,
    input [4:0] A1, A2, A3,
    input [31:0] WD3,

    output [31:0] RD1, RD2,
    output [31:0] s0_reg // for testing purposes
);

reg [31:0] register_file [0:31];

// wiring address of register $zero to zero directly, and mapping other addresses to their value.
assign RD1 = (A1 != 5'b0) ? register_file[A1] : 32'b0;
assign RD2 = (A2 != 5'b0) ? register_file[A2] : 32'b0;

assign s0_reg = register_file[16];

always @(posedge clk) begin
    if(WE3) begin
        if(A3 != 5'b0) register_file[A3] <= WD3;
    end
end

endmodule