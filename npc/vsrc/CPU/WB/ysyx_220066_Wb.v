module ysyx_220066_Wb(
    input clk,rst,

    input M_wen_in,M_MemRd_in,M_done_in,
    input [4:0] M_rd_in,
    input [63:0] M_data_in,
    input [63:0] data_Rd,
    input data_Rd_valid,

    input Multi_wen_in,
    input [4:0] Multi_rd_in,
    input [63:0] Multi_data_in,

    input Div_wen_in,
    input [4:0] Div_rd_in,
    input [63:0] Div_data_in,

    output reg [4:0] rd,
    output reg [63:0] data,
    output wen,m_block,multi_block,div_block
);
    reg M_wen_native,M_MemRd_native,Multi_wen_native,Div_wen_native;
    reg M_done_native;
    reg [4:0] M_rd_native;
    reg [4:0] Div_rd_native;
    reg [4:0] Multi_rd_native;
    reg [63:0] M_data_native;
    reg [63:0] Multi_data_native;
    reg [63:0] Div_data_native;
    
    always @(posedge clk) begin
        M_wen_native<=M_wen_in;M_MemRd_native<=M_MemRd_in;M_done_native<=M_done_in;
        M_rd_native<=M_rd_in;M_data_native<=M_data_in;

        Multi_wen_native<=Multi_wen_in;
        Multi_rd_native<=Multi_rd_in;Multi_data_native<=Multi_data_in;

        Div_wen_native<=Div_wen_in;
        Div_rd_native<=Div_rd_in;Div_data_native<=Div_data_in;
    end

    assign wen=~rst&&((M_wen_native&&(data_Rd_valid||~M_MemRd_native))||Div_wen_native||Multi_wen_native);
    assign m_block=M_wen_native&&M_MemRd_native&&~data_Rd_valid;
    assign div_block=Div_wen_native&&(M_wen_native&&(M_MemRd_native||~data_Rd_valid));
    assign multi_block=Multi_wen_native&&(Div_wen_native||(M_wen_native&&(M_MemRd_native||~data_Rd_valid)));

    always @(*) begin
        if(M_wen_native&&(data_Rd_valid||~M_MemRd_native)) begin
            data=M_MemRd_native?data_Rd:M_data_native;
            rd=M_rd_native;
        end else if(Div_wen_native) begin
            data=Div_data_native;
            rd=Div_rd_native;
        end else begin
            data=Multi_data_native;
            rd=Multi_rd_native;
        end
    end
    
    always @(*) begin
        //
    end
endmodule
