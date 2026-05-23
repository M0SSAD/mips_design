typedef enum logic [1:0] {
  R_TYPE,
  I_TYPE,
  J_TYPE
} instr_type_e;

typedef enum logic [5:0] {
  r_type = 0,
  j = 2,
  beq = 4,
  addi = 8,
  lw = 35,
  sw = 43
} opcode_e;

typedef enum logic [5:0] {
  add  = 32,
  sub  = 34,
  andd = 36,
  orr  = 37,
  slt  = 42
} funct_e;

typedef enum logic [4:0] {
  rs_t0 = 8,
  rs_t1,
  rs_t2,
  rs_t3,
  rs_t4,
  rs_t5,
  rs_t6,
  rs_t7 = 15,
  rs_s0 = 16,
  rs_s1,
  rs_s2,
  rs_s3,
  rs_s4,
  rs_s5,
  rs_s6,
  rs_s7,
  rs_t8,
  rs_t9 = 25
} rs_e;

typedef enum logic [4:0] {
  rt_t0 = 8,
  rt_t1,
  rt_t2,
  rt_t3,
  rt_t4,
  rt_t5,
  rt_t6,
  rt_t7 = 15,
  rt_s0 = 16,
  rt_s1,
  rt_s2,
  rt_s3,
  rt_s4,
  rt_s5,
  rt_s6,
  rt_s7,
  rt_t8,
  rt_t9 = 25
} rt_e;

typedef enum logic [4:0] {
  rd_t0 = 8,
  rd_t1,
  rd_t2,
  rd_t3,
  rd_t4,
  rd_t5,
  rd_t6,
  rd_t7 = 15,
  rd_s0 = 16,
  rd_s1,
  rd_s2,
  rd_s3,
  rd_s4,
  rd_s5,
  rd_s6,
  rd_s7,
  rd_t8,
  rd_t9 = 25
} rd_e;

//////////////////////////////////////////////////////////////////////////////////

typedef struct packed {
  opcode_e opcode;
  rs_e rs;
  rt_e rt;
  rd_e rd;
  logic [4:0] shamt;
  funct_e funct;

} R_TYPE_e;

typedef struct packed {
  opcode_e opcode;
  rs_e rs;
  rt_e rt;
  logic signed [15:0] immediate;

} I_TYPE_e;

typedef struct packed {
  opcode_e opcode;
  logic signed [25:0] immediate;

} J_TYPE_e;

//////////////////////////////////////////////////////////////////////////////////

class transaction;

  rand logic [31:0] instruction;
  rand R_TYPE_e R_TYPE_instruction;
  rand I_TYPE_e I_TYPE_instruction;
  rand J_TYPE_e J_TYPE_instruction;
  rand instr_type_e option;
  constraint instr_constr {
    if (option == R_TYPE) {
      instruction == R_TYPE_instruction;
    } else
    if (option == I_TYPE) {
      instruction == I_TYPE_instruction;
    } else
    if (option == J_TYPE) {instruction == J_TYPE_instruction;}
  }
  constraint instr_dist_constr {
    option dist {
      R_TYPE := 60,
      I_TYPE := 40,
      J_TYPE := 10
    };
  }
endclass


module tb_sc_mips ();
  //////////////////////////////////////////
  parameter clk_period = 10;
  logic clk;
  logic rst_n;
  initial begin
    clk = 0;
    forever #(clk_period / 2) clk = ~clk;

  end


  //////////////////////////////////////////
  transaction t = new();
  integer fd;
  sc_mips MIPSTOP (
      .clk (clk),
      .rst_n(rst_n)
  );
  task write_instruction_file(transaction t, integer fd);
    fd = $fopen("mem.dat", "w");
    for (int i = 0; i < 1024; i = i + 1) begin
      assert (t.randomize());
      $fdisplay(fd, "%h", t.instruction[7:0]);
      $fdisplay(fd, "%h", t.instruction[15:8]);
      $fdisplay(fd, "%h", t.instruction[23:16]);
      $fdisplay(fd, "%h", t.instruction[31:24]);
    end
    $fclose(fd);
  endtask
  initial begin
    #(clk_period * 5);
    $readmemh("mem.dat", MIPSTOP.instruction_memory_unit.mem);
    $display("DEBUG: Byte 0 is %h, Byte 1 is %h", MIPSTOP.instruction_memory_unit.mem[0], MIPSTOP.instruction_memory_unit.mem[1]);
    $display("DEBUG Instr: %h", MIPSTOP.instruction_memory_unit.rd_data);

    rst_n = 0;
    #(clk_period * 2);
    rst_n = 1;
    #(clk_period * 40);

    $display("\n========================================");
    $display("       AUTOMATED MIPS TEST REPORT       ");
    $display("========================================");

    // 1. Check the Intermediate Math Results
    
    if (MIPSTOP.rf_unit.register_file[17] !== 32'h000004B0) $display("FAIL: $s1 (Reg 17) | Expected: 000004B0 | Got: %h", MIPSTOP.rf_unit.register_file[17]);
    else $display("PASS: $s1 Initialization");

    if (MIPSTOP.rf_unit.register_file[18] !== 32'h00000FA0) $display("FAIL: $s2 (Reg 18) | Expected: 00000FA0 | Got: %h", MIPSTOP.rf_unit.register_file[18]);
    else $display("PASS: ADD Instruction");

    if (MIPSTOP.rf_unit.register_file[19] !== 32'h00000640) $display("FAIL: $s3 (Reg 19) | Expected: 00000640 | Got: %h", MIPSTOP.rf_unit.register_file[19]);
    else $display("PASS: SUB Instruction");

    if (MIPSTOP.rf_unit.register_file[20] !== 32'h000000B0) $display("FAIL: $s4 (Reg 20) | Expected: 000000B0 | Got: %h", MIPSTOP.rf_unit.register_file[20]);
    else $display("PASS: AND Instruction");

    if (MIPSTOP.rf_unit.register_file[21] !== 32'h00000EF0) $display("FAIL: $s5 (Reg 21) | Expected: 00000EF0 | Got: %h", MIPSTOP.rf_unit.register_file[21]);
    else $display("PASS: OR Instruction");

    if (MIPSTOP.rf_unit.register_file[13] !== 32'h00000AF0) $display("FAIL: $t5 (Reg 13) | Expected: 00000AF0 | Got: %h", MIPSTOP.rf_unit.register_file[13]);
    else $display("PASS: SW / LW Instructions");


    // 2. Check the Ultimate Success/Fail Flag in $s0
    $display("----------------------------------------");
    if (MIPSTOP.rf_unit.register_file[16] === 32'hFFFFD08E) begin
        $display(">>> FINAL STATUS: ALL TESTS PASSED! <<<");
    end else if (MIPSTOP.rf_unit.register_file[16] === 32'hFFFFDEAD) begin
        $display(">>> FINAL STATUS: FAILED (Hit ERROR Branch) <<<");
    end else begin
        $display(">>> FINAL STATUS: UNKNOWN ERROR (Check PC and logic) <<<");
    end
    $display("========================================\n");

    $stop;
  end
endmodule