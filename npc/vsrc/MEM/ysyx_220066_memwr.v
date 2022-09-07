module ysyx_220066_memwr (
    input clk,rst,MemWr,
    input [63:0] addr,
    input [7:0] wmask,
    input [63:0] data
);
    import "DPI-C" function void data_write(
        input longint waddr, input longint data, input byte mask
    );

    always @(posedge clk) begin
    //    if(!rst&&MemWr)$display("pc=%h,addr=%h,MemOp=%h,wmask=%h,data=%h",pc,addr,MemOp,wmask,data_Wr);
        if(~rst&&MemWr) data_write(addr,data,wmask);
    end
endmodule