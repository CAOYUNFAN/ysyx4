module ysyx_220066_M (
    input  clk,in_valid,in_dead,MemToReg,in_RegWr,rst,
    input [31:0] in_BusB,
    input [31:0] ALUout,
    input [4:0] in_rd,

    input [31:0] data_read,
    output [31:0] m_out
    );

    assign m_out=MemToReg?data_read:ALUout;

endmodule
