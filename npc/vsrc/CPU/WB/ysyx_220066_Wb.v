module ysyx_220066_Wb(
    input clk,rst,

    input wen_in,MemRd_in,done_in,valid_in,error_in,
    input [4:0] rd_in,
    input [63:0] data_in,
    input [63:0] data_Rd,
    input [63:0] nxtpc_in,
    input data_Rd_error,

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
    output wen//,multi_block,div_block
);
    wire error;
    wire [63:0] nxtpc;
    wire done,valid;


    reg wen_native,MemRd_native,valid_native;//Multi_wen_native,Div_wen_native;
    reg done_native;
    reg error_native;//Multi_error_native,Div_error_native;
    reg [4:0] rd_native;
//    reg [4:0] Div_rd_native;
//    reg [4:0] Multi_rd_native;
    reg [63:0] data_native;
//    reg [63:0] Multi_data_native;
//    reg [63:0] Div_data_native;
    reg [63:0] nxtpc_native;
//    reg [63:0] Multi_nxtpc_native;
//    reg [63:0] Div_nxtpc_native;    
    always @(posedge clk) begin
        wen_native<=wen_in&&valid_in;MemRd_native<=MemRd_in;done_native<=done_in;
        rd_native<=rd_in;data_native<=data_in;nxtpc_native<=nxtpc_in;valid_native<=valid_in;
        error_native<=error_in;

/*        Multi_wen_native<=Multi_wen_in;Multi_error_native<=Multi_error_in;
        Multi_rd_native<=Multi_rd_in;Multi_data_native<=Multi_data_in;Multi_nxtpc_native<=Multi_nxtpc_in;

        Div_wen_native<=Div_wen_in;Div_error_native<=Div_error_in;
        Div_rd_native<=Div_rd_in;Div_data_native<=Div_data_in;Div_nxtpc_native<=Div_nxtpc_in;*/
    end

    assign error=error_native||(data_Rd_error&&MemRd_native);
    assign wen=~rst&&wen_native&&~error;
//    assign div_block=Div_wen_native&&(wen_native&&(MemRd_native||~data_Rd_valid));
//    assign multi_block=Multi_wen_native&&(Div_wen_native||(wen_native&&(MemRd_native||~data_Rd_valid)));

    assign data=MemRd_native?data_Rd:data_native;
    assign rd=rd_native;
    assign nxtpc=nxtpc_native;

    assign done=done_native;
    assign valid=valid_native;//||Multi_wen_native||Div_wen_native;

    always @(*) begin
        `ifdef INSTR
        if(~rst&&~clk) $display("WB:nxtpc=%h,data=%h,valid=%b,done=%b,error=%b",nxtpc,data,valid,done,error);
        `endif
    end
endmodule
