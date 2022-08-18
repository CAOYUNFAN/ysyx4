module ysyx_220066_M (
    input clk,rst,block,valid_in,
    output ready,
    output reg valid,

    input valid_in,
    input MemRd,MemWr,
    input [63:0] alu_result,
    input [63:0] data_Rd,
    input error_rd,
    output reg [63:0] m_out
);
    always @(posedge clk) begin
        if(rst) valid<=0;
        else if(~(block&&valid)) valid<=valid_in&&MemWr;
    end

    assign m_out=MemToReg?data_read:ALUout;

endmodule
