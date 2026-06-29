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
    input [4:0] ALU_control,
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
        5'b00000: alu_out = srcA & srcB; // and
        5'b00001: alu_out = srcA | srcB; // or
        5'b00010: alu_out = srcA + srcB; // add
        5'b00011: alu_out = ~(srcA | srcB); // nor
        5'b00100: alu_out = srcA ^ srcB; // xor
        5'b00110: alu_out = srcA - srcB; // sub
        5'b00111: alu_out = (srcA < srcB)? 32'b1 : 32'b0; // slt
        5'b01000: alu_out = (srcB << shamt); // sll
        5'b01001: alu_out = (srcB >> shamt); // srl
        5'b01010: alu_out = (srcB >>> shamt); // sra
        5'b01011: alu_out = (srcB << srcA[4:0]);  // sllv
        5'b01100: alu_out = (srcB >> srcA[4:0]);  // srlv
        5'b01101: alu_out = (srcB >>> srcA[4:0]); // srav
        5'b01110: alu_out = ($unsigned(srcA) < $unsigned(srcB))? 32'b1 : 32'b0; // sltu
        5'b01111: alu_out = $unsigned(srcA) + $unsigned(srcB); // addu
        5'b10000: alu_out = $unsigned(srcA) - $unsigned(srcB); // subu
        5'b10001: alu_out = srcB; // lui
        default: alu_out = srcA;
    endcase
end

assign zero_flg = (alu_out == 0);   
assign gt = ($signed(srcA) > $signed(srcB));
assign lt = ($signed(srcA) < $signed(srcB));
endmodule
