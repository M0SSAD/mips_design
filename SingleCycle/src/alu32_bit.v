/**
Inputs:
    1 - srcA
    2 - srcB
    3 - ALU_control: 3-bits Alu Control Signal
        000 -> and
        001 -> or
        010 -> add
        011 -> nor
        100 -> xor
        110 -> sub
        111 -> slt
Output:
    1 - alu_out
    2 - zero_flg
    3 - gt: greater than
    4 - lt: less than
*/

module alu32_bit(
    input signed [31:0] srcA, srcB,
    input [3:0] ALU_control,
    input [4:0] shamt,
    output reg [31:0]  alu_out,
    output zero_flg, gt, lt
);

// // Logic For Manual Set Less Than, because it is a signed comparison.
// wire slt_different_signs = (srcA[31] != src[31]);
// wire a_is_negative = src[31];
// wire slt = slt_different_signs? a_is_negative : (srcA < srcB);

always@(*)
begin
    case (ALU_control)
        4'b0000: alu_out = srcA & srcB; // and
        4'b0001: alu_out = srcA | srcB; // or
        4'b0010: alu_out = srcA + srcB; // add
        4'b0011: alu_out = ~(srcA | srcB); // nor
        4'b0100: alu_out = srcA ^ srcB; // xor
        4'b0110: alu_out = srcA - srcB; // sub
        4'b0111: alu_out = (srcA < srcB)? 32'b1 : 32'b0; // slt
        4'b1000: alu_out = (srcB << shamt); // sll
        4'b1001: alu_out = (srcB >> shamt); // srl
        4'b1010: alu_out = (srcB >>> shamt); // sra
        4'b1011: alu_out = (srcB << srcA[4:0]);  // sllv
        4'b1100: alu_out = (srcB >> srcA[4:0]);  // srlv
        4'b1101: alu_out = (srcB >>> srcA[4:0]); // srav
        default: alu_out = srcA;
    endcase
end

assign zero_flg = (alu_out == 0);   
assign gt = (srcA > srcB);
assign lt = (srcA < srcB);
endmodule
