module ysyx_220066_M (
    input clk,rst,valid_in,block,
    output ready,valid,

    input RegWr_in,MemRd_in,MemWr_in,done_in,
    input [63:0] ex_result,
    input [63:0] data_Wr_in,
    input [63:0] nxtpc_in,
    input [2:0] MemOp_in,
    input [4:0] rd_in,
    input error_in,
    output reg MemRd_native,MemWr_native,
    output reg [2:0] MemOp_native,
    output reg [63:0] addr,
    output reg [63:0] data_Wr,
    output [4:0] rd,
    output RegWr
);
    wire error,done;
    wire [63:0] nxtpc;

    reg valid_native;
    always @(posedge clk) valid_native<=~rst&&valid_in;

    assign ready=~block;

    reg done_native,error_native,RegWr_native;
    reg [63:0] nxtpc_native;
    reg [4:0] rd_native;

    always @(posedge clk) if(!block) begin
        MemRd_native<=MemRd_in;
        MemWr_native<=MemWr_in;
        RegWr_native<=RegWr_in;
        done_native<=done_in;
        addr<=ex_result;
        error_native<=error_in;
        nxtpc_native<=nxtpc_in;
        data_Wr<=data_Wr_in;
        MemOp_native<=MemOp_in;
        rd_native<=rd_in;
        $display("MM:data_Wr=%h,data_Wr_in=%h",data_Wr,data_Wr_in);
    end

    assign valid=valid_native;
    assign done=done_native;
    assign error=error_native;
    assign nxtpc=nxtpc_native;
    assign RegWr=RegWr_native;
    assign rd=rd_native;

    always @(*) begin
        if(~rst&&~clk) $display("M:nxtpc=%h,valid=%b,Memrd=%b,MemWr=%b,data_wr=%h,in=%h,error=%b",nxtpc,valid,MemRd_native,MemWr_native,data_Wr,data_Wr_in,error);
    end

    always @(*) begin
        if(~rst&&clk) $display("M:data_Wr=%h,data_Wr_in=%h",data_Wr,data_Wr_in);
    end
endmodule
