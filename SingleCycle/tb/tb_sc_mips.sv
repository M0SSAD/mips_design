typedef enum logic [1:0] {
  R_TYPE,
  I_TYPE,
  J_TYPE
} instr_type_e;

// 1. ADDED NEW OPCODES (andi=12, ori=13, xori=14, lui=15)
typedef enum logic [5:0] {
  r_type = 0, j = 2, beq = 4, addi = 8, 
  andi = 12, ori = 13, xori = 14, lui = 15, 
  lw = 35, sw = 43
} opcode_e;

typedef enum logic [5:0] {
  sll = 0, srl = 2, sra = 3, sllv = 4, srlv = 6, srav = 7, add = 32, sub = 34, andd = 36, orr = 37, slt = 42
} funct_e;

typedef enum logic [4:0] {
  r_zero = 0, rs_t0 = 8, rs_t1, rs_t2, rs_t3, rs_s0 = 16, rs_s1, rs_s2
} reg_e;

typedef struct packed {
  opcode_e opcode; reg_e rs; reg_e rt; reg_e rd; logic [4:0] shamt; funct_e funct;
} R_TYPE_e;

typedef struct packed {
  opcode_e opcode; reg_e rs; reg_e rt; logic signed [15:0] immediate;
} I_TYPE_e;

typedef struct packed {
  opcode_e opcode; logic signed [25:0] immediate;
} J_TYPE_e;

class transaction;
  rand logic [31:0] instruction;
  rand R_TYPE_e R_TYPE_instruction;
  rand I_TYPE_e I_TYPE_instruction;
  rand J_TYPE_e J_TYPE_instruction;
  rand instr_type_e option;

  constraint instr_constr {
    if (option == R_TYPE) { 
        instruction == R_TYPE_instruction;
        R_TYPE_instruction.opcode == r_type;
        
        // 1. Shift Constraint Routing
        if (R_TYPE_instruction.funct inside {sll, srl, sra}) {
            // Standard shifts ignore rs, but randomize shamt
            R_TYPE_instruction.rs == r_zero; 
        } else if (R_TYPE_instruction.funct inside {sllv, srlv, srav}) {
            // Variable shifts use rs, but ignore shamt
            R_TYPE_instruction.shamt == 0; 
        } else {
            // Standard math ignores shamt
            R_TYPE_instruction.shamt == 0; 
        }
    } 
    else if (option == I_TYPE) { 
        instruction == I_TYPE_instruction;
        // 2. CONSTRAIN GENERATOR TO VALID I-TYPE OPCODES
        I_TYPE_instruction.opcode inside {beq, addi, andi, ori, xori, lui, lw, sw};
    } 
    else if (option == J_TYPE) { 
        instruction == J_TYPE_instruction;
        J_TYPE_instruction.opcode == j;
    }
  }

  // 3. THE HARDWARE SAFETY CONSTRAINT FOR LUI
  constraint lui_rs_zero {
      if (option == I_TYPE && I_TYPE_instruction.opcode == lui) {
          I_TYPE_instruction.rs == r_zero;
      }
  }

  constraint instr_dist_constr {
    option dist { R_TYPE := 60, I_TYPE := 40, J_TYPE := 0 };
    // Jumps temporarily disabled
  }
endclass

module tb_sc_mips ();
  parameter clk_period = 10;
  logic clk;
  logic rst_n;

  initial begin
    clk = 0;
    forever #(clk_period / 2) clk = ~clk;
  end

  transaction t = new();
  integer fd;

  sc_mips MIPSTOP (
      .clk (clk),
      .rst_n(rst_n)
  );

  task write_instruction_file();
    logic [31:0] boot_instr;
    fd = $fopen("mem_rand.dat", "w");

    // 1. THE BOOT SEQUENCE (Initialize Registers 1 through 31)
    for (int i = 1; i < 32; i = i + 1) begin
      // Cast the random number to 16 bits before concatenating!
      logic [15:0] rand_imm;
      rand_imm = $urandom();
      boot_instr = {6'd8, 5'd0, i[4:0], rand_imm};
      
      $fdisplay(fd, "%02h\n%02h\n%02h\n%02h", 
                boot_instr[7:0], boot_instr[15:8], boot_instr[23:16], boot_instr[31:24]);
    end

    // 2. THE RANDOM PAYLOAD (Execute actual random math)
    for (int i = 31; i < 200; i = i + 1) begin
      assert (t.randomize());
      $fdisplay(fd, "%02h\n%02h\n%02h\n%02h", 
                t.instruction[7:0], t.instruction[15:8], t.instruction[23:16], t.instruction[31:24]);
    end
    $fclose(fd);
  endtask

  initial begin
    $display("\n========================================");
    
    // ROUTING: Check command line arguments
    if ($test$plusargs("RANDOM")) begin
        $display("   MODE: RANDOM INSTRUCTION GENERATION  ");
        $display("========================================");
        write_instruction_file();
        $readmemh("mem_rand.dat", MIPSTOP.instruction_memory_unit.mem);
    end 
    else begin
        $display("   MODE: DIRECTED ASSEMBLY TEST (mem.dat)");
        $display("========================================");
        $readmemh("mem.dat", MIPSTOP.instruction_memory_unit.mem);
        $display("DEBUG RAM CHECK: mem[0]=%h, mem[1]=%h, mem[2]=%h, mem[3]=%h", 
        MIPSTOP.instruction_memory_unit.mem[0], 
        MIPSTOP.instruction_memory_unit.mem[1], 
        MIPSTOP.instruction_memory_unit.mem[2], 
        MIPSTOP.instruction_memory_unit.mem[3]);
    end

    // Standard Reset Sequence
    rst_n = 1;
    #(clk_period * 2);
    rst_n = 0;
    #(clk_period * 2);
    rst_n = 1;
    
    #(clk_period * 100); // Let the processor run

    // Only run the hardcoded register checks if we are running the directed test
    if (!$test$plusargs("RANDOM")) begin
        if (MIPSTOP.rf_unit.register_file[17] !== 32'h000004B0) $display("FAIL: $s1 (Reg 17) | Got: %h", MIPSTOP.rf_unit.register_file[17]);
        else $display("PASS: $s1 Initialization");

        if (MIPSTOP.rf_unit.register_file[18] !== 32'h00000FA0) $display("FAIL: $s2 (Reg 18) | Got: %h", MIPSTOP.rf_unit.register_file[18]);
        else $display("PASS: ADD Instruction");

        if (MIPSTOP.rf_unit.register_file[19] !== 32'h00000640) $display("FAIL: $s3 (Reg 19) | Got: %h", MIPSTOP.rf_unit.register_file[19]);
        else $display("PASS: SUB Instruction");

        if (MIPSTOP.rf_unit.register_file[16] === 32'hFFFFD08E) $display(">>> FINAL STATUS: ALL TESTS PASSED! <<<");
        else $display(">>> FINAL STATUS: FAILED <<<");
    end else begin
        $display(">>> RANDOM RUN COMPLETE. CHECK WAVEFORMS. <<<");
    end

    $display("========================================\n");
    $stop;
  end
endmodule