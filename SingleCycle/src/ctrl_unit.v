module ctrl_unit (
    input wire [5:0] funct, opcode,
    input wire [4:0] rt,
    output reg [2:0] mem_to_reg, mem_type, // Expanded
    output reg [2:0] branch_type, reg_dst, ext_ctrl, md_ctrl,
    output reg mem_write, alu_src, reg_write, jump, jump_register, md_en,
    output reg [4:0] alu_control
);
reg [2:0] alu_op;

always @(*) begin
  // Defaults
  jump = 0; jump_register = 0; md_en = 0; md_ctrl = 2'b00; mem_type = 3'b000;
  
  case (opcode) 
   6'b000000 : begin // R-Type
        reg_write = (funct != 6'b001000 && funct != 6'b011000 && funct != 6'b011010 && funct != 6'b011001 && funct != 6'b011011); // jr, mult, div, multu, divu don't write to GPR
        reg_dst=2'b01; alu_src=0; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b010; ext_ctrl=2'b00; 
        
        if (funct == 6'b001000) begin jump = 1; jump_register = 1; end // jr
        if (funct == 6'b011000) begin md_en = 1; md_ctrl = 2'b00; end  // mult
        if (funct == 6'b011001) begin md_en = 1; md_ctrl = 2'b01; end  // multu
        if (funct == 6'b011010) begin md_en = 1; md_ctrl = 2'b10; end  // div
        if (funct == 6'b011011) begin md_en = 1; md_ctrl = 2'b11; end  // divu
        if (funct == 6'b010000) begin mem_to_reg = 3'b011; end         // mfhi
        if (funct == 6'b010010) begin mem_to_reg = 3'b100; end         // mflo
        // ADD JAL.
   end 
   
   // Memory Instructions
   6'b100011 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b000; end // lw 
   6'b101011 : begin reg_write=0; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=1; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b000; end // sw
   6'b100000 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b010; end // lb
   6'b100100 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b100; end // lbu
   6'b100001 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b001; end // lh
   6'b100101 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b011; end // lhu
   6'b101000 : begin reg_write=0; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=1; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b010; end // sb
   6'b101001 : begin reg_write=0; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=1; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b001; end // sh
   
   // Branch & Jumps
   6'b000100 : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=3'b001; mem_write=0; mem_to_reg=3'b000; alu_op=3'b001; ext_ctrl=2'b00; end // beq
   6'b000101 : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=3'b010; mem_write=0; mem_to_reg=3'b000; alu_op=3'b001; ext_ctrl=2'b00; end // bne
   6'b000111 : begin reg_write=0; reg_dst=2'b00; alu_src=1; branch_type=3'b100; mem_write=0; mem_to_reg=3'b000; alu_op=3'b001; ext_ctrl=2'b11; end // bgtz
   6'b000001 : begin reg_write=0; reg_dst=2'b00; alu_src=1; mem_write=0; mem_to_reg=3'b000; alu_op=3'b001; ext_ctrl=2'b11;
    if(rt == 5'b00000) branch_type=3'b011; /*bltz*/ else begin branch_type=3'b101; end /*bgez*/
    end
   6'b000010 : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b000; jump=1; ext_ctrl=2'b00; end // j
   6'b000011 : begin reg_write=1; reg_dst=2'b10; alu_src=0; branch_type=3'b000; mem_write=0; mem_to_reg=3'b010; alu_op=3'b000; jump=1; ext_ctrl=2'b00; end // jal
   
   // I-Type Math
   6'b001000 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; end // addi
   6'b001001 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; end // addiu
   6'b001100 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b011; ext_ctrl=2'b01; end // andi
   6'b001101 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b100; ext_ctrl=2'b01; end // ori
   6'b001110 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b101; ext_ctrl=2'b01; end // xori
   6'b001111 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b111; ext_ctrl=2'b10; end // lui
   6'b001010 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b110; ext_ctrl=2'b00; end // slti
   6'b001011 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b110; ext_ctrl=2'b01; end // sltiu
   
   default   : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=3'b000; mem_write=0; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; end 
  endcase 
end


always @(*) begin
    casex({alu_op, funct}) 
        9'b000_xxxxxx: alu_control = 5'b00010; // I-Type ADD (lw, sw, addi)
        9'b111_xxxxxx: alu_control = 5'b10001; // LUI
        9'b001_xxxxxx: alu_control = 5'b00110; // I-Type SUB (beq, bne, bltz)
        9'b011_xxxxxx: alu_control = 5'b00000; // I-Type AND (andi)
        9'b100_xxxxxx: alu_control = 5'b00001; // I-Type OR  (ori)
        9'b101_xxxxxx: alu_control = 5'b00100; // I-Type XOR (xori)
        9'b110_xxxxxx: alu_control = 5'b00111; // slti/ sltiu
        
        // R-Types
        9'b010_100000: alu_control = 5'b00010; // add
        9'b010_100001: alu_control = 5'b01111; // addu
        9'b010_100010: alu_control = 5'b00110; // sub
        9'b010_100011: alu_control = 5'b10000; // subu
        9'b010_100100: alu_control = 5'b00000; // and
        9'b010_100101: alu_control = 5'b00001; // or
        9'b010_100110: alu_control = 5'b00100; // xor
        9'b010_100111: alu_control = 5'b00011; // nor
        9'b010_101010: alu_control = 5'b00111; // slt
        9'b010_101011: alu_control = 5'b01110; // sltu

        
        // Shifts
        9'b010_000000: alu_control = 5'b01000; // sll
        9'b010_000010: alu_control = 5'b01001; // srl
        9'b010_000011: alu_control = 5'b01010; // sra
        9'b010_000100: alu_control = 5'b01011; // sllv
        9'b010_000110: alu_control = 5'b01100; // srlv
        9'b010_000111: alu_control = 5'b01101; // srav
        
        default: alu_control = 5'b00010;
    endcase
end
endmodule