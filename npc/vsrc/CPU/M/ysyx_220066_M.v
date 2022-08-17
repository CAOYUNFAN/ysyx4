module ysyx_220066_M (
    input clk,rst,block,
    output ready,valid,

    input valid_in,
    input MemRd,MemWr,
    input [63:0] addr,

    output [63:0] m_out
);
    always @(posedge clk) begin
        if(rst) valid<=0;
        else if(~(block&&valid)) valid<=valid_in&&MemWr;
    end



    assign m_out=MemToReg?data_read:ALUout;

endmodule
