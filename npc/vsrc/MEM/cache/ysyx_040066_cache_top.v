module ysyx_040066_cache_top (
    input clk,rst,force_update,

    //CPU
    //[63:32] [31:11] [10:6] [5:3] [2:0]
    input valid,op,//op 0:read,1:write
    input [IDNEX_LEN-1:0] index,
    input [TAG_LEN-1:0] tag,
    input [OFFSET_LEN-1:0] offset,
    input [7:0] wstrb,
    input [63:0] wdata,
    output ok,
    output ready,
    output reg [63:0] rdata,
    output reg rw_error,
    input fence,

    //AXI
    output reg [31:0] addr,
    output reg rd_req,
    input rd_ready,
    input rd_error,
    input [LINE_LEN-1:0] rd_data,
    output reg wr_req,
    output [LINE_LEN-1:0] wr_data,
    input wr_ready,wr_error

    `ifdef TEST_EMU
    
    `endif
);

endmodule