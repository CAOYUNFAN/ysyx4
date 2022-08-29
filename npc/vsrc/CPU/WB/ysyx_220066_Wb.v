module ysyx_220066_Wb(
    input clk,rst,

    input M_wen_in,M_MemRd_in,M_done_in,M_valid_in,M_error_in,
    input [4:0] M_rd_in,
    input [63:0] M_data_in,
    input [63:0] data_Rd,
    input [63:0] M_nxtpc_in,
    input data_Rd_valid,data_Rd_error,

/*    input Multi_wen_in,Multi_error_in,
    input [4:0] Multi_rd_in,
    input [63:0] Multi_data_in,
    input [63:0] Multi_nxtpc_in,

    input Div_wen_in,Div_error_in,
    input [4:0] Div_rd_in,
    input [63:0] Div_data_in,
    input [63:0] Div_nxtpc_in,*/

    output [4:0] rd,
    output [63:0] data,
    output wen,m_block//,multi_block,div_block
);
    wire error;
    wire [63:0] nxtpc;
    wire done,valid;


    reg M_wen_native,M_MemRd_native,M_valid_native;//Multi_wen_native,Div_wen_native;
    reg M_done_native;
    reg M_error_native;//Multi_error_native,Div_error_native;
    reg [4:0] M_rd_native;
//    reg [4:0] Div_rd_native;
//    reg [4:0] Multi_rd_native;
    reg [63:0] M_data_native;
//    reg [63:0] Multi_data_native;
//    reg [63:0] Div_data_native;
    reg [63:0] M_nxtpc_native;
//    reg [63:0] Multi_nxtpc_native;
//    reg [63:0] Div_nxtpc_native;    
    always @(posedge clk) begin
        M_wen_native<=M_wen_in&&M_valid_in;M_MemRd_native<=M_MemRd_in;M_done_native<=M_done_in;
        M_rd_native<=M_rd_in;M_data_native<=M_data_in;M_nxtpc_native<=M_nxtpc_in;M_valid_native<=M_valid_in;
        M_error_native<=M_error_in;

/*        Multi_wen_native<=Multi_wen_in;Multi_error_native<=Multi_error_in;
        Multi_rd_native<=Multi_rd_in;Multi_data_native<=Multi_data_in;Multi_nxtpc_native<=Multi_nxtpc_in;

        Div_wen_native<=Div_wen_in;Div_error_native<=Div_error_in;
        Div_rd_native<=Div_rd_in;Div_data_native<=Div_data_in;Div_nxtpc_native<=Div_nxtpc_in;*/
    end

    assign wen=~rst&&(M_wen_native&&(data_Rd_valid||~M_MemRd_native));
    assign m_block=M_wen_native&&M_MemRd_native&&~data_Rd_valid;
//    assign div_block=Div_wen_native&&(M_wen_native&&(M_MemRd_native||~data_Rd_valid));
//    assign multi_block=Multi_wen_native&&(Div_wen_native||(M_wen_native&&(M_MemRd_native||~data_Rd_valid)));

    assign data=M_MemRd_native?data_Rd:M_data_native;
    assign rd=M_rd_native;
    assign nxtpc=M_nxtpc_native;
    assign error=M_error_native||(data_Rd_error&&M_MemRd_native);

    assign done=M_done_native;
    assign valid=M_valid_native;//||Multi_wen_native||Div_wen_native;

    always @(*) begin
        if(!rst&&~clk) $display("WB:nxtpc=%h,valid=%b,done=%b,error=%b,",nxtpc,valid,done,error);
        else $display("WB:error=%b",error);
    end
endmodule
