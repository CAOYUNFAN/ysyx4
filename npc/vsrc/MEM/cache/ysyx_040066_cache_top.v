module ysyx_040066_cache_top(
    input clk,rst,force_update,
    input valid,op,read,
    input [4:0] index,
    input [20:0] tag,
    input [2:0] offset,
    input [7:0] wstrb,
    input [63:0] wdata,
    output ok,
    output ready,
    output [63:0] rdata,
    output rw_error,
    input fence,

    `ifndef TEST_CACHE
    input [127:0] ram_Q [3:0],
    output [127:0] ram_D [3:0],
    output [127:0] ram_BWEN,
    output [5:0] ram_A,
    output ram_WEN,
    `endif

    //AXI
    output [31:0] addr,
    output rd_req,
    input rd_ready,
    input rd_error,
    input rd_last,
    input [63:0] rd_data,
    output wr_req,
    output [511:0] wr_data,
    input wr_ready,wr_error
);
    `ifdef TEST_CACHE
    wire [127:0] ram_Q [3:0];
    wire [127:0] ram_D [3:0];
    wire [127:0] ram_BWEN;
    wire ram_WEN;
    wire [5:0] ram_A;
    `endif

    ysyx_040066_cache cache(
        .clk(clk),.rst(rst),.force_update(force_update),

        .valid(valid),.op(op),.read(read),
        .index(index),.tag(tag),.offset(offset),
        .wstrb(wstrb),.wdata(wdata),.ok(ok),.ready(ready),
        .rdata(rdata),.rw_error(rw_error),.fence(fence),

        .addr(addr),.rd_req(rd_req),.rd_ready(rd_ready),
        .rd_error(rd_error),.rd_last(rd_last),.rd_data(rd_data),
        .wr_req(wr_req),.wr_data(wr_data),.wr_ready(wr_ready),.wr_error(wr_error),

        .Q(ram_Q),.D(ram_D),.A(ram_A),.BWEN(ram_BWEN),.WEN(ram_WEN)
    );

    `ifdef TEST_CACHE
    genvar x;generate for(x=0;x<4;x=x+1) begin: SRAM
        S011HD1P_X32Y2D128_BW sram(
            .Q(ram_Q[x]),.CLK(clk),.CEN(1'b0),.BWEN(ram_BWEN),
            .A(ram_A),.D(ram_D[x]),.WEN(ram_WEN)
        );
    end endgenerate
    `endif

endmodule
