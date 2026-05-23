module mult_div(
    input clk, rst_n,
    input [31:0] srcA, srcB,
    input md_en,             // Enable multiplication/division
    input [1:0] md_ctrl,     // 0: mult, 1: multu, 2: div, 3: divu
    output reg [31:0] hi_out,
    output reg [31:0] lo_out
);
    wire signed [31:0] signed_A = srcA;
    wire signed [31:0] signed_B = srcB;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hi_out <= 32'b0;
            lo_out <= 32'b0;
        end else if (md_en) begin
            case (md_ctrl)
                2'b00: {hi_out, lo_out} <= signed_A * signed_B;          // mult
                2'b01: {hi_out, lo_out} <= srcA * srcB;                  // multu
                2'b10: begin hi_out <= signed_A % signed_B; lo_out <= signed_A / signed_B; end // div
                2'b11: begin hi_out <= srcA % srcB; lo_out <= srcA / srcB; end                 // divu
            endcase
        end
    end
endmodule