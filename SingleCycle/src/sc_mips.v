module sc_mips(
    input clk, rst_n
);

    wire [2:0] alu_ctrl;
    wire reg_write, alu_src, mem_to_reg, mem_write, branch, jump;

    wire[31:0] pc_current, pc_next, pc_plus_4;
    wire[31:0] instr;
    wire[31:0] srcA, srcB, rd2;
    wire[31:0] alu_out;
    wire[31:0] sign_ext_imm;
    wire[31:0] mem_rd_data;
    wire[31:0] write_back_data;
    wire[3:0] s0_reg;
    wire reg_dst;
    wire [4:0] write_reg_addr;
    wire [31:0] branch_target;
    wire [31:0] jump_target;
    wire zero_flag, gt_flag, lt_flag;
    wire pc_src_branch = branch & zero_flag;
    wire [31:0] branch_pc_mux;
    // construct the address of the target that we will jump or branch to.
    assign jump_target = {pc_plus_4[31:28], instr[25:0], 2'b00};
    assign branch_target = pc_plus_4 + (sign_ext_imm << 2); 
    // which bits of the instructions are your destination address?
    assign write_reg_addr = reg_dst ? instr[15:11] : instr[20:16];
    // which is the second operand in the ALU, an immediate value or a value from a register.
    assign srcB = alu_src ? sign_ext_imm : rd2;
    // What is written into the register file, a read data from the memory or the output of the alu.
    assign write_back_data = mem_to_reg ? mem_rd_data : alu_out;
    assign pc_plus_4 = pc_current + 4;
    // MUXs to determine the next value of the program counter.
    assign branch_pc_mux = pc_src_branch ? branch_target : pc_plus_4;
    assign pc_next = jump ? jump_target : branch_pc_mux; 

    pc_reg pc_unit (
        .clk(clk),
        .rst_n(rst_n),
        .pc_next(pc_next),
        .pc(pc_current)
    );

    rf rf_unit(
        .clk(clk),
        .WE3(reg_write),
        .A1(instr[25:21]),
        .A2(instr[20:16]),
        .A3(write_reg_addr),
        .WD3(write_back_data),
        .RD1(srcA),
        .RD2(rd2),
        .s0_reg(s0_reg)
    );

    ctrl_unit control_unit(
        .funct(instr[5:0]),
        .opcode(instr[31:26]),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .mem_write(mem_write),
        .alu_control(alu_ctrl),
        .alu_src(alu_src),
        .reg_dst(reg_dst),
        .reg_write(reg_write),
        .jump(jump)
    );

    alu32_bit alu32_bit_unit(
        .srcA(srcA),
        .srcB(srcB),
        .ALU_control(alu_ctrl),
        .alu_out(alu_out),
        .zero_flg(zero_flag),
        .gt(gt_flag),
        .lt(lt_flag)
    );


    ram_memory ram_memory_unit(
        .clk(clk),
        .wr_en(mem_write),
        .addr(alu_out[9:0]),
        .wr_data(rd2),
        .rd_data(mem_rd_data)
    );

    ram_memory instruction_memory_unit(
        .clk(clk),
        .wr_en(1'b0),
        .addr(pc_current[9:0]),
        .wr_data(32'b0),
        .rd_data(instr)
    );

    sign_extend sign_extend_unit(
        .imm(instr[15:0]),
        .imm_sign(sign_ext_imm)
    );

endmodule