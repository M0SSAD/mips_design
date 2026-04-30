module sign_extend(
    input [15:0] imm,
    output [31:0] imm_sign
);

assign imm_sign = {{16{imm[15]}}, imm}; // takes the signed bit, extends it to 16 bit, and adds them to the 16 bit imm value.

endmodule