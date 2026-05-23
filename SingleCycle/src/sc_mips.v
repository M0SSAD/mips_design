module sc_mips(
    input clk, rst_n
);

    wire [3:0] alu_ctrl;
    wire reg_write, alu_src, mem_write, jump, jump_register;
    wire [1:0] branch_type, reg_dst, mem_to_reg; // Upgraded to 2-bit
    
    wire[31:0] pc_current, pc_next, pc_plus_4;
    wire[31:0] instr, srcA, srcB, rd2, alu_out, ext_imm, mem_rd_data;
    wire [1:0] ext_ctrl;
    wire[3:0] s0_reg;
    
    wire [31:0] branch_target, jump_target, branch_pc_mux;
    wire zero_flag, gt_flag, lt_flag;
    
    // The Branch Evaluator
    reg pc_src_branch;
    always @(*) begin
        case (branch_type)
            2'b01: pc_src_branch = zero_flag;       // beq
            2'b10: pc_src_branch = ~zero_flag;      // bne
            2'b11: pc_src_branch = lt_flag;         // bltz (srcA < 0)
            default: pc_src_branch = 1'b0;          // No branch
        endcase
    end

    // Destination Register
    reg [4:0] write_reg_addr;
    always @(*) begin
        case (reg_dst)
            2'b00: write_reg_addr = instr[20:16]; // I-Type ($rt)
            2'b01: write_reg_addr = instr[15:11]; // R-Type ($rd)
            2'b10: write_reg_addr = 5'd31;        // jal ($ra)
            default: write_reg_addr = 5'd0;
        endcase
    end

    // Write Back Data
    reg [31:0] write_back_data;
    always @(*) begin
        case (mem_to_reg)
            2'b00: write_back_data = alu_out;
            2'b01: write_back_data = mem_rd_data;
            2'b10: write_back_data = pc_plus_4;   // jal (Save Return Address)
            default: write_back_data = 32'b0;
        endcase
    end

    // Datapath Connections
    assign srcB = alu_src ? ext_imm : rd2;
    assign pc_plus_4 = pc_current + 4;
    assign branch_target = pc_plus_4 + (ext_imm << 2); 
    
    // Jump Target Logic
    assign jump_target = jump_register ? srcA : {pc_plus_4[31:28], instr[25:0], 2'b00};
    
    // PC Routing
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
        .jump(jump),
        .jump_register(jump_register),
        .ext_ctrl(ext_ctrl)
    );

    alu32_bit alu32_bit_unit(
        .srcA(srcA),
        .srcB(srcB),
        .shamt(instr[10:6]),
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

    extend extension_Unit(
        .imm(instr[15:0]),
        .ext_imm(ext_imm),
        .ext_ctrl(ext_ctrl)
    );

endmodule