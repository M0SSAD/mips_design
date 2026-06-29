module sc_mips #(parameter depth_of_instruction_memory = 1024) (
    input clk, rst_n
);
    wire [3:0] alu_ctrl;
    wire reg_write, alu_src, mem_write, jump, jump_register;
    wire md_en;
    wire [1:0] branch_type, reg_dst, ext_ctrl, md_ctrl; 
    wire [2:0] mem_to_reg, mem_type;
    
    wire[31:0] pc_current, pc_next, pc_plus_4;
    wire[31:0] instr, srcA, srcB, rd2, alu_out, ext_imm, ram_rd_data, aligned_rd_data, ram_wr_data;
    wire [3:0] s0_reg, byte_en;
    wire [31:0] hi_out, lo_out;
    
    wire [31:0] branch_target, jump_target, branch_pc_mux;
    wire zero_flag, gt_flag, lt_flag;
    
    // MUX 1: The Branch Evaluator 
    reg pc_src_branch;
    always @(*) begin
        case (branch_type)
            2'b01: pc_src_branch = zero_flag;       // beq
            2'b10: pc_src_branch = ~zero_flag;      // bne
            2'b11: pc_src_branch = lt_flag;         // bltz
            default: pc_src_branch = 1'b0;
        endcase
    end

    // MUX 2: Destination Register 
    reg [4:0] write_reg_addr;
    always @(*) begin
        case (reg_dst)
            2'b00: write_reg_addr = instr[20:16]; // rt
            2'b01: write_reg_addr = instr[15:11]; // rd
            2'b10: write_reg_addr = 5'd31;        // ra
            default: write_reg_addr = 5'd0;
        endcase
    end

    // MUX 3: Write Back Data
    reg [31:0] write_back_data;
    always @(*) begin
        case (mem_to_reg)
            3'b000: write_back_data = alu_out;
            3'b001: write_back_data = aligned_rd_data;
            3'b010: write_back_data = pc_plus_4;   
            3'b011: write_back_data = hi_out;      // mfhi
            3'b100: write_back_data = lo_out;      // mflo
            default: write_back_data = 32'b0;
        endcase
    end

    // Datapath Connections
    assign srcB = alu_src ? ext_imm : rd2;
    assign pc_plus_4 = pc_current + 4;
    assign branch_target = pc_plus_4 + (ext_imm << 2);
    assign jump_target = jump_register ? srcA : {pc_plus_4[31:28], instr[25:0], 2'b00};
    assign branch_pc_mux = pc_src_branch ? branch_target : pc_plus_4;
    assign pc_next = jump ? jump_target : branch_pc_mux;

    pc_reg pc_unit (.clk(clk), .rst_n(rst_n), .pc_next(pc_next), .pc(pc_current));

    rf rf_unit(
        .clk(clk), .WE3(reg_write),
        .A1(instr[25:21]), .A2(instr[20:16]), .A3(write_reg_addr),
        .WD3(write_back_data),
        .RD1(srcA), .RD2(rd2), .s0_reg(s0_reg)
    );

    ctrl_unit control_unit(
        .funct(instr[5:0]), .opcode(instr[31:26]),
        .mem_to_reg(mem_to_reg), .branch_type(branch_type), .mem_write(mem_write),
        .alu_control(alu_ctrl), .alu_src(alu_src), .reg_dst(reg_dst),
        .reg_write(reg_write), .jump(jump), .jump_register(jump_register), .ext_ctrl(ext_ctrl),
        .mem_type(mem_type), .md_en(md_en), .md_ctrl(md_ctrl)
    );

    alu32_bit alu32_bit_unit(
        .srcA(srcA), .srcB(srcB), .shamt(instr[10:6]),
        .ALU_control(alu_ctrl), .alu_out(alu_out),
        .zero_flg(zero_flag), .gt(gt_flag), .lt(lt_flag)
    );

    mem_ctrl mem_ctrl_unit(
        .addr_offset(alu_out[1:0]), .mem_type(mem_type), .mem_write(mem_write),
        .rt_data(rd2), .ram_rd_data(ram_rd_data),
        .byte_en(byte_en), .ram_wr_data(ram_wr_data), .aligned_rd_data(aligned_rd_data)
    );

    ram_memory ram_memory_unit(
        .clk(clk), .byte_en(byte_en), .addr({alu_out[9:2], 2'b00}), // 10 bits for 1024 locations, each 4 locations describe a word,
        .wr_data(ram_wr_data), .rd_data(ram_rd_data)
    );

    ram_memory #(.depth(depth_of_instruction_memory)) instruction_memory_unit( // Hardwired to read only
        .clk(clk), .byte_en(4'b0000), .addr(pc_current[$clog2(depth_of_instruction_memory)-1:0]),
        .wr_data(32'b0), .rd_data(instr)
    );

    extend extension_Unit(.imm(instr[15:0]), .ext_imm(ext_imm), .ext_ctrl(ext_ctrl));

    mult_div mult_div_unit(
        .clk(clk), .rst_n(rst_n), .srcA(srcA), .srcB(srcB),
        .md_en(md_en), .md_ctrl(md_ctrl), .hi_out(hi_out), .lo_out(lo_out)
    );
endmodule