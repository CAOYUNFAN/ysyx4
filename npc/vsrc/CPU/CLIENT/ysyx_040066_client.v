module ysyx_220066_clinet (
    input clk,rst,
    input [63:0] addr,
    input MemRd,MemWr,
    input [63:0] data,

    output MemRd_real,MemWr_real,intr,
    output reg [63:0] data_rd,
    output reg MemRd_time,error
);
    reg [63:0] mtime,mtimecmp;
    wire data_valid;
    assign data_valid=(addr>=64'h2000000)&&(addr<64'h200c000);
    assign MemRd_real=MemRd&&~data_valid;
    assign MemWr_real=MemWr&&~data_valid;

    always @(posedge clk) MemRd_time<=~MemRd_real;
    always @(posedge clk) error<=addr[15:0]!=16'h4000&&addr[15:0]!=16'hbff8&&data_valid;

    always @(posedge clk) begin
        if(rst) begin
            mtime<=0;
            mtimecmp<=64'h100;
        end else if(MemWr&&data_valid) begin
            mtime<=(addr[15:0]==16'hbff8)?data:mtime+64'h1;
            mtimecmp<=(addr[15:0]==16'h4000)?data:mtimecmp;
        end else mtime<=mtime+64'h1;
    end

    assign intr=(mtime>mtimecmp);
    always @(posedge clk) data_rd<=(addr[15:0]==16'h4000)?mtimecmp:mtime;

    always @(*) begin
        //if(~clk&&~rst) $display("CLIENT:%h,%h",mtime,mtimecmp);
    end
endmodule