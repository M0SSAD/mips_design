typedef enum logic [1:0] {
  R_TYPE,
  I_TYPE,
  J_TYPE
} instr_type_e;

// Expanded Opcodes (Added lb=32, lh=33, lbu=36, sb=40, sh=41)
typedef enum logic [5:0] {
  r_type = 0, j = 2, beq = 4, addi = 8, 
  andi = 12, ori = 13, xori = 14, lui = 15, 
  lb = 32, lh = 33, lw = 35, lbu = 36, sb = 40, sh = 41, sw = 43
} opcode_e;

// Expanded Funct Codes (Added mfhi=16, mflo=18, mult=24, div=26)
typedef enum logic [5:0] {
  sll = 0, srl = 2, sra = 3, sllv = 4, srlv = 6, srav = 7, 
  jr = 8, mfhi = 16, mflo = 18, mult = 24, multu = 25, div = 26, divu = 27,
  add = 32, sub = 34, andd = 36, orr = 37, slt = 42
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
            R_TYPE_instruction.rs == r_zero; 
        } else if (R_TYPE_instruction.funct inside {sllv, srlv, srav}) {
            R_TYPE_instruction.shamt == 0; 
        
        // 2. Multiplier/Divider Constraints
        } else if (R_TYPE_instruction.funct inside {mult, multu, div, divu}) {
            R_TYPE_instruction.rd == r_zero;
            R_TYPE_instruction.shamt == 0;
            
        // 3. Move from HI/LO Constraints
        } else if (R_TYPE_instruction.funct inside {mfhi, mflo}) {
            R_TYPE_instruction.rs == r_zero;
            R_TYPE_instruction.rt == r_zero;
            R_TYPE_instruction.shamt == 0;
            
        } else {
            R_TYPE_instruction.shamt == 0; 
        }
    } 
    else if (option == I_TYPE) { 
        instruction == I_TYPE_instruction;
        // 4. Memory/Immediate Constraint Routing
        I_TYPE_instruction.opcode inside {beq, addi, andi, ori, xori, lui, lb, lh, lw, lbu, sb, sh, sw};
    } 
    else if (option == J_TYPE) { 
        instruction == J_TYPE_instruction;
        J_TYPE_instruction.opcode inside {j}; // Excluded jal for random testing to avoid crashing ra
    }
  }

  constraint lui_rs_zero {
      if (option == I_TYPE && I_TYPE_instruction.opcode == lui) {
          I_TYPE_instruction.rs == r_zero;
      }
  }

  constraint instr_dist_constr {
    option dist { R_TYPE := 50, I_TYPE := 50, J_TYPE := 0 };
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

  sc_mips #(.depth_of_instruction_memory(1024)) MIPSTOP (
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
        $readmemh("mem.mem", MIPSTOP.instruction_memory_unit.mem);
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
        if (MIPSTOP.rf_unit.register_file[16] === 32'h1337BEEF) begin
            $display("========================================");
            $display(">>> FINAL STATUS: ALL TESTS PASSED! <<<");
            $display("========================================");
        end else if (MIPSTOP.rf_unit.register_file[16] === 32'hDEADDEAD) begin
            $display("========================================");
            $display(">>> FINAL STATUS: FAILED AT AN ASSERTION <<<");
            $display("========================================");
        end else begin
            $display("========================================");
            $display(">>> FINAL STATUS: UNKNOWN FAILURE (CRASH) <<<");
            $display("========================================");
        end
    end else begin
        $display(">>> RANDOM RUN COMPLETE. CHECK WAVEFORMS. <<<");
    end

    $display("========================================\n");
    $stop;
  end
endmodule