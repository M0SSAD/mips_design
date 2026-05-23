# --- BASIC MATH & LOGIC ---
00: addi $t1, $zero, 5        # t1 = 5
04: ori  $t2, $zero, 10       # t2 = 10
08: add  $t3, $t1, $t2        # t3 = 15
0C: sub  $t4, $t2, $t1        # t4 = 5
10: bne  $t4, $t1, FAIL       # ASSERT: 5 == 5 (Branches to FAIL if broken)

# --- SHIFT DATAPATH ---
14: sll  $t6, $t1, 1          # t6 = 5 << 1 = 10
18: beq  $t6, $t2, PASS_S     # ASSERT: 10 == 10 (Branches over the FAIL trap)
1C: j    FAIL                 # If it didn't branch, hardware is broken
20: PASS_S: jal FUNC          # $ra gets 36 (0x24). Jump to FUNC at 40 (0x28).

# --- RETURN JUMP TRAP ---
24: j    PASS_FUNC            # This is where jr $ra lands! Jump over the function.
28: FUNC: addi $t7, $zero, 42 # t7 = 42
2C: jr   $ra                  # Jump back to PC=36 (0x24)
30: PASS_FUNC: addi $t8, $zero, 42 
34: bne  $t7, $t8, FAIL       # ASSERT: Function successfully executed and returned

# --- MEMORY SUB-WORDS ---
38: lui  $t0, 0x1234          
3C: ori  $t0, $t0, 0x5678     # t0 = 0x12345678
40: addi $s1, $zero, 100      # Address = 100
44: sw   $t0, 0($s1)          # Save Word to RAM
48: lb   $t9, 0($s1)          # Load Byte (Should fetch 0x78 due to Little Endian)
4C: addi $s2, $zero, 0x78     
50: bne  $t9, $s2, FAIL       # ASSERT: 0x78 == 0x78

# --- HI/LO MULTIPLIER ---
54: addi $s3, $zero, 10       # s3 = 10
58: addi $s4, $zero, 3        # s4 = 3
5C: div  $s3, $s4             # LO = 10/3=3, HI = 10%3=1
60: mflo $s5                  # s5 = 3
64: mfhi $s6                  # s6 = 1
68: bne  $s5, $s4, FAIL       # ASSERT: LO == 3
6C: addi $s7, $zero, 1        
70: bne  $s6, $s7, FAIL       # ASSERT: HI == 1

# --- SUCCESS ---
74: lui  $s0, 0x1337          
78: ori  $s0, $s0, 0xBEEF     # $s0 = 0x1337BEEF (Tests Passed!)
7C: END: beq $zero, $zero, END# Infinite Loop to halt processor

# --- FAILURE ---
80: FAIL: lui $s0, 0xDEAD     
84: ori  $s0, $s0, 0xDEAD     # $s0 = 0xDEADDEAD (Test Failed)
88: j    END