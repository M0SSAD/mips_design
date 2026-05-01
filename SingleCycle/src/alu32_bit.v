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
    input [2:0] ALU_control,
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
        3'b000: alu_out = srcA & srcB; 
        3'b001: alu_out = srcA | srcB;
        3'b010: alu_out = srcA + srcB;
        3'b011: alu_out = ~(srcA | srcB);
        3'b100: alu_out = srcA ^ srcB;
        3'b110: alu_out = srcA - srcB;
        3'b111: alu_out = (srcA < srcB)? 32'b1 : 32'b0;
        default: alu_out = srcA;
    endcase
end

assign zero_flg = (alu_out == 0);   
assign gt = (srcA > srcB);
assign lt = (srcA < srcB);
endmodule
