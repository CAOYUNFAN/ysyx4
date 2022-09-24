module ysyx_040066_M (
    input clk,rst,valid_in,block,
    output valid,

    input RegWr_in,MemRd_in,MemWr_in,done_in,
    input [63:0] ex_result,
    input [63:0] data_Wr_in,
    input [63:0] nxtpc_in,
    input [2:0] MemOp_in,
    input [4:0] rd_in,
    input error_in,fence_i_in,
    input is_mul_in,is_div_in,div_valid,
    input [63:0] mul_result,
    input [63:0] div_result,
    input [7:0] wr_mask_in,

    output reg MemRd_native,MemWr_native,fence_i,
    output reg [63:0] addr,
    output reg [63:0] data_Wr,
    output [4:0] rd,
    output reg [7:0] wr_mask,
    output reg [2:0] wr_len,
    output RegWr
);
    wire error,done;
    wire [63:0] nxtpc;
    wire [63:0] data;

    reg valid_native;
    always @(posedge clk) valid_native<=~rst&&(block?valid_native:valid_in);

    reg done_native,error_native,RegWr_native;
    reg [63:0] nxtpc_native;
    reg [4:0] rd_native;
    reg [2:0] MemOp_native;
    reg is_mul_native,is_div_native;

    always @(posedge clk) if(~block) begin
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
        is_mul_native<=is_mul_in;
        is_div_native<=is_div_in;
        wr_mask<=wr_mask_in;
        fence_i<=fence_i_in&&valid_in&&~error_in;
        case (MemOp_in[1:0])
            2'b00:wr_len<=3'b011;
            2'b01:wr_len<=3'b100;
            2'b10:wr_len<=3'b101;
            2'b11:wr_len<=3'b110;
        endcase
        //$display("MM:data_Wr=%h,data_Wr_in=%h",data_Wr,data_Wr_in);
    end

    assign valid=valid_native&&(div_valid||~is_div_native);
    assign done=done_native;
    assign error=error_native;
    assign nxtpc=nxtpc_native;
    assign RegWr=RegWr_native;
    assign rd=rd_native;
    assign data=is_mul_native?mul_result:(is_div_native?div_result:addr);

    always @(*) begin
        `ifdef INSTR
        if(~rst&&~clk) $display("M:nxtpc=%h,valid=%b,Memrd=%b,MemWr=%b,data=%h,error=%b",nxtpc,valid,MemRd_native,MemWr_native,data,error);
        `endif 
    end

endmodule
