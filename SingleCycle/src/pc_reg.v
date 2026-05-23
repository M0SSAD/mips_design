/**
Inputs:
    1 - clk
    2 - rst : to reset the PC register.
    3 - pc_next : next address to be executed.
Output:
    1 - pc : the current executing address.
*/
module pc_reg(
    input clk, rst_n,
    input [31:0] pc_next,
    output reg [31:0] pc
);

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
      pc <= 32'b0;
    end else begin
      pc <= pc_next;
    end
end

endmodule