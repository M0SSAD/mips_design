module mem_ctrl(
    input [1:0] addr_offset, // alu_out[1:0]
    input [2:0] mem_type,    // 0: Word, 1: Half, 2: Byte, 3: Half(U), 4: Byte(U)
    input mem_write,
    input [31:0] rt_data,    // Data from Register File to write
    input [31:0] ram_rd_data,// Raw Data from RAM
    output reg [3:0] byte_en,
    output reg [31:0] ram_wr_data,
    output reg [31:0] aligned_rd_data
);

    // 1. Write Alignment and Byte Enables
    always @(*) begin
        byte_en = 4'b0000;
        ram_wr_data = rt_data;
        if (mem_write) begin
            case (mem_type)
                3'b000: begin // sw
                    byte_en = 4'b1111; 
                end
                3'b001: begin // sh
                    byte_en = (addr_offset[1]) ? 4'b1100 : 4'b0011;
                    ram_wr_data = {rt_data[15:0], rt_data[15:0]}; // Replicate to both lanes
                end
                3'b010: begin // sb
                    case (addr_offset)
                        2'b00: byte_en = 4'b0001;
                        2'b01: byte_en = 4'b0010;
                        2'b10: byte_en = 4'b0100;
                        2'b11: byte_en = 4'b1000;
                    endcase
                    ram_wr_data = {4{rt_data[7:0]}}; // Replicate across all lanes
                end
            endcase
        end
    end

    // 2. Read Alignment and Extension
    reg [15:0] ext_half;
    reg [7:0]  ext_byte;
    
    always @(*) begin
        // Extract the specific halfword or byte
        ext_half = (addr_offset[1]) ? ram_rd_data[31:16] : ram_rd_data[15:0];
        case (addr_offset)
            2'b00: ext_byte = ram_rd_data[7:0];
            2'b01: ext_byte = ram_rd_data[15:8];
            2'b10: ext_byte = ram_rd_data[23:16];
            2'b11: ext_byte = ram_rd_data[31:24];
        endcase

        // Format for the Register File
        case (mem_type)
            3'b000: aligned_rd_data = ram_rd_data;                        // lw
            3'b001: aligned_rd_data = {{16{ext_half[15]}}, ext_half};     // lh
            3'b010: aligned_rd_data = {{24{ext_byte[7]}}, ext_byte};      // lb
            3'b011: aligned_rd_data = {16'b0, ext_half};                  // lhu
            3'b100: aligned_rd_data = {24'b0, ext_byte};                  // lbu
            default: aligned_rd_data = 32'b0;
        endcase
    end
endmodule