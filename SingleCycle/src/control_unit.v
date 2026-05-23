module ctrl_unit (
    input wire [5:0]  funct, opcode,
    output reg [2:0] mem_to_reg, mem_type, // Expanded
    output reg [1:0] branch_type, reg_dst, ext_ctrl, md_ctrl,
    output reg mem_write, alu_src, reg_write, jump, jump_register, md_en,
    output reg [3:0] alu_control
);
reg [2:0] alu_op;

always @(*) begin
  // Safe Defaults
  jump = 0; jump_register = 0; md_en = 0; md_ctrl = 2'b00; mem_type = 3'b000;
  
  case (opcode) 
   6'b000000 : begin // R-Type
        reg_write = (funct != 6'b001000 && funct != 6'b011000 && funct != 6'b011010); // jr, mult, div don't write to GPR
        reg_dst=2'b01; alu_src=0; branch_type=2'b00; mem_write=0; mem_to_reg=3'b000; alu_op=3'b010; ext_ctrl=2'b00; 
        
        if (funct == 6'b001000) begin jump = 1; jump_register = 1; end // jr
        if (funct == 6'b011000) begin md_en = 1; md_ctrl = 2'b00; end  // mult
        if (funct == 6'b011010) begin md_en = 1; md_ctrl = 2'b10; end  // div
        if (funct == 6'b010000) begin mem_to_reg = 3'b011; end         // mfhi
        if (funct == 6'b010010) begin mem_to_reg = 3'b100; end         // mflo
   end 
   
   // Memory Instructions (Added Sub-Word)
   6'b100011 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b000; end // lw 
   6'b101011 : begin reg_write=0; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=1; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b000; end // sw
   6'b100000 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b010; end // lb
   6'b100100 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b100; end // lbu
   6'b100001 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b001; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b001; end // lh
   6'b101000 : begin reg_write=0; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=1; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b010; end // sb
   6'b101001 : begin reg_write=0; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=1; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; mem_type=3'b001; end // sh
   
   // Branch & Jumps
   6'b000100 : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=2'b01; mem_write=0; mem_to_reg=3'b000; alu_op=3'b001; ext_ctrl=2'b00; end // beq
   6'b000101 : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=2'b10; mem_write=0; mem_to_reg=3'b000; alu_op=3'b001; ext_ctrl=2'b00; end // bne
   6'b000001 : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=2'b11; mem_write=0; mem_to_reg=3'b000; alu_op=3'b001; ext_ctrl=2'b00; end // bltz
   6'b000010 : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=2'b00; mem_write=0; mem_to_reg=3'b000; alu_op=3'b000; jump=1; ext_ctrl=2'b00; end // j
   6'b000011 : begin reg_write=1; reg_dst=2'b10; alu_src=0; branch_type=2'b00; mem_write=0; mem_to_reg=3'b010; alu_op=3'b000; jump=1; ext_ctrl=2'b00; end // jal
   
   // I-Type Math
   6'b001000 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; end // addi
   6'b001100 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b000; alu_op=3'b011; ext_ctrl=2'b01; end // andi
   6'b001101 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b000; alu_op=3'b100; ext_ctrl=2'b01; end // ori
   6'b001110 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b000; alu_op=3'b101; ext_ctrl=2'b01; end // xori
   6'b001111 : begin reg_write=1; reg_dst=2'b00; alu_src=1; branch_type=2'b00; mem_write=0; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b10; end // lui
   
   default   : begin reg_write=0; reg_dst=2'b00; alu_src=0; branch_type=2'b00; mem_write=0; mem_to_reg=3'b000; alu_op=3'b000; ext_ctrl=2'b00; end 
  endcase 
end

// ALU Decoder (Leave unchanged from your previous implementation)
always @(*) begin
    casex({alu_op, funct}) 
        9'b000_xxxxxx: alu_control = 4'b0010; // I-Type ADD (lw, sw, addi, lui)
        9'b001_xxxxxx: alu_control = 4'b0110; // I-Type SUB (beq, bne, bltz)
        9'b011_xxxxxx: alu_control = 4'b0000; // I-Type AND (andi)
        9'b100_xxxxxx: alu_control = 4'b0001; // I-Type OR  (ori)
        9'b101_xxxxxx: alu_control = 4'b0100; // I-Type XOR (xori)
        
        // R-Types
        9'b010_100000: alu_control = 4'b0010; // add
        9'b010_100010: alu_control = 4'b0110; // sub
        9'b010_100100: alu_control = 4'b0000; // and
        9'b010_100101: alu_control = 4'b0001; // or
        9'b010_101010: alu_control = 4'b0111; // slt
        
        // Shifts
        9'b010_000000: alu_control = 4'b1000; // sll
        9'b010_000010: alu_control = 4'b1001; // srl
        9'b010_000011: alu_control = 4'b1010; // sra
        9'b010_000100: alu_control = 4'b1011; // sllv
        9'b010_000110: alu_control = 4'b1100; // srlv
        9'b010_000111: alu_control = 4'b1101; // srav
        
        default: alu_control = 4'b0010;
    endcase
end
endmodule