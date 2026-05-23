module ctrl_unit (
    // inputs
    input wire [5:0]  funct,
    input wire [5:0]  opcode,
    // outputs
    output reg mem_to_reg,
    output reg branch,     
    output reg mem_write,
    output reg [2:0] alu_control,
    output reg alu_src,
    output reg reg_dst,
    output reg reg_write,
    output reg jump,
    output reg [1:0] ext_ctrl
);
reg [2:0] alu_op;
// Identify the instruction using the opcode.
always @(*) begin
  case (opcode) 
   6'b000000 : begin reg_write=1; reg_dst=1; alu_src=0; branch=0; mem_write=0; mem_to_reg=0; alu_op=3'b010; jump=0; ext_ctrl=2'b00; end //R-type
   6'b100011 : begin reg_write=1; reg_dst=0; alu_src=1; branch=0; mem_write=0; mem_to_reg=1; alu_op=3'b000; jump=0; ext_ctrl=2'b00; end // lw 
   6'b101011 : begin reg_write=0; reg_dst=0; alu_src=1; branch=0; mem_write=1; mem_to_reg=0; alu_op=3'b000; jump=0; ext_ctrl=2'b00; end // sw
   6'b000100 : begin reg_write=0; reg_dst=0; alu_src=0; branch=1; mem_write=0; mem_to_reg=0; alu_op=3'b001; jump=0; ext_ctrl=2'b00; end // beq
   6'b001000 : begin reg_write=1; reg_dst=0; alu_src=1; branch=0; mem_write=0; mem_to_reg=0; alu_op=3'b000; jump=0; ext_ctrl=2'b00; end // addi
   6'b001100 : begin reg_write=1; reg_dst=0; alu_src=1; branch=0; mem_write=0; mem_to_reg=0; alu_op=3'b011; jump=0; ext_ctrl=2'b01; end // andi
   6'b001101 : begin reg_write=1; reg_dst=0; alu_src=1; branch=0; mem_write=0; mem_to_reg=0; alu_op=3'b100; jump=0; ext_ctrl=2'b01; end // ori
   6'b001110 : begin reg_write=1; reg_dst=0; alu_src=1; branch=0; mem_write=0; mem_to_reg=0; alu_op=3'b101; jump=0; ext_ctrl=2'b01; end // xori
   6'b001111 : begin reg_write=1; reg_dst=0; alu_src=1; branch=0; mem_write=0; mem_to_reg=0; alu_op=3'b000; jump=0; ext_ctrl=2'b10; end // lui
   6'b000010 : begin reg_write=0; reg_dst=0; alu_src=0; branch=0; mem_write=0; mem_to_reg=0; alu_op=3'b000; jump=1; ext_ctrl=2'b00; end // j
   default   : begin reg_write=1; reg_dst=1; alu_src=1; branch=0; mem_write=0; mem_to_reg=0; alu_op=3'b000; jump=0; ext_ctrl=2'b00; end // default to add
  endcase 
end

// based on the alu_op specify the alu operation.
always @(*) begin
    casex({alu_op, funct}) 
        9'b000_xxxxxx: alu_control = 3'b010; // I-Type ADD (lw, sw, addi, lui)
        9'b001_xxxxxx: alu_control = 3'b110; // I-Type SUB (beq)
        9'b011_xxxxxx: alu_control = 3'b000; // I-Type AND (andi)
        9'b100_xxxxxx: alu_control = 3'b001; // I-Type OR  (ori)
        9'b101_xxxxxx: alu_control = 3'b100; // I-Type XOR (xori)
        
        // R-Types (alu_op == 010)
        9'b010_100000: alu_control = 3'b010; // add
        9'b010_100010: alu_control = 3'b110; // sub
        9'b010_100100: alu_control = 3'b000; // and
        9'b010_100101: alu_control = 3'b001; // or
        9'b010_101010: alu_control = 3'b111; // slt
        default: alu_control = 3'b010;
    endcase
end
endmodule