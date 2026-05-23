module extend (
    input [15:0] imm,
    input [1:0] ext_ctrl,
    output reg [31:0] ext_imm
);

always @(*) begin
    case (ext_ctrl)
        2'b00: ext_imm = {{16{imm[15]}}, imm}; // Sign extend
        2'b01: ext_imm = {16'b0, imm}; // unsigned extension
        2'b10: ext_imm = {imm, 16'b0}; // upper extension
        default: ext_imm = 32'b0;
    endcase

end


endmodule