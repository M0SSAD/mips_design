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
    output reg jump
);
reg [1:0] alu_op;
always @(*) begin
  case (opcode) 
   6'b000000 : begin reg_write=1; reg_dst=1; alu_src=0; branch=0; mem_write=0; mem_to_reg=0; alu_op=2'b10; jump=0; end //R-type
   6'b100011 : begin reg_write=1; reg_dst=0; alu_src=1; branch=0; mem_write=0; mem_to_reg=1; alu_op=2'b00; jump=0; end // lw 
   6'b101011 : begin reg_write=0; reg_dst=0; alu_src=1; branch=0; mem_write=1; mem_to_reg=0; alu_op=2'b00; jump=0; end // sw
   6'b000100 : begin reg_write=0; reg_dst=0; alu_src=0; branch=1; mem_write=0; mem_to_reg=0; alu_op=2'b01; jump=0; end // beq
   6'b001000 : begin reg_write=1; reg_dst=0; alu_src=1; branch=0; mem_write=0; mem_to_reg=0; alu_op=2'b00; jump=0; end // addi
   6'b000010 : begin reg_write=1; reg_dst=0; alu_src=0; branch=0; mem_write=0; mem_to_reg=0; alu_op=2'b00; jump=1; end // j
   default      : begin reg_write=1; reg_dst=1; alu_src=0; branch=0; mem_write=0; mem_to_reg=0; alu_op=2'b00; jump=1; end 
  endcase  
end

always @(*) begin
    casex({alu_op, funct}) 
        8'b00_xxxxxx: alu_control = 3'b010; //add
        8'bx1_xxxxxx: alu_control = 3'b110; //sub
        8'b1x_100000: alu_control = 3'b010; //add
        8'b1x_100010: alu_control = 3'b110; //sub   
        8'b1x_100100: alu_control = 3'b000; //and
        8'b1x_100101: alu_control = 3'b001; //or
        8'b1x_101010: alu_control = 3'b111; //slt 
    endcase
end
endmodule