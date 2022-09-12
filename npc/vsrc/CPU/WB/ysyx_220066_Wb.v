module ysyx_220066_Wb(
    input clk,rst,

    input wen_in,MemRd_in,MemWr_in,done_in,valid_in,error_in,
    input [4:0] rd_in,
    input [63:0] data_in,
    input [63:0] data_Rd,
    input [63:0] nxtpc_in,
    input [2:0] MemOp_in,
    input data_error,
    input [2:0] addr_lowbit_in,

    output [4:0] rd,
    output [63:0] data,
    output wen
);
    wire error;
    wire [63:0] nxtpc;
    wire done,valid;


    reg wen_native,MemRd_native,MemWr_native,valid_native;
    reg done_native;
    reg error_native;
    reg [4:0] rd_native;
    reg [63:0] data_native;
    reg [63:0] nxtpc_native;
    reg [2:0] MemOp_native;  
    reg [2:0] addr_lowbit_native;
    always @(posedge clk) begin
        wen_native<=wen_in&&valid_in;MemRd_native<=MemRd_in;MemWr_native<=MemWr_in;done_native<=done_in;
        rd_native<=rd_in;data_native<=data_in;nxtpc_native<=nxtpc_in;valid_native<=valid_in;
        error_native<=error_in;MemOp_native<=MemOp_in;addr_lowbit_native<=addr_lowbit_in;
    end

    assign error=error_native||(data_error&&(MemRd_native||MemWr_native));
    assign wen=~rst&&wen_native&&~error;
//    assign div_block=Div_wen_native&&(wen_native&&(MemRd_native||~data_Rd_valid));
//    assign multi_block=Multi_wen_native&&(Div_wen_native||(wen_native&&(MemRd_native||~data_Rd_valid)));
    wire [63:0] real_read_data;

    ysyx_220066_data_choose data_choose(
        .MemOp(MemOp_native),.addr_low(addr_lowbit_native),.basic_data(data_Rd),
        .data(real_read_data)
    );

    assign data=MemRd_native?real_read_data:data_native;
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

module ysyx_220066_data_choose(
    input [2:0] MemOp,
    input [2:0] addr_low,
    input [63:0] basic_data,

    output reg [63:0] data
);
    reg [7:0] b_Rd;
    reg [15:0] h_Rd;
    reg [31:0] w_Rd;
    always @(*) begin
        case(addr_low)
            3'b000:begin b_Rd=basic_data[ 7: 0]; h_Rd=basic_data[15: 0]; w_Rd=basic_data[31: 0];end
            3'b001:begin b_Rd=basic_data[15: 8]; h_Rd=basic_data[15: 0]; w_Rd=basic_data[31: 0];end
            3'b010:begin b_Rd=basic_data[23:16]; h_Rd=basic_data[31:16]; w_Rd=basic_data[31: 0];end
            3'b011:begin b_Rd=basic_data[31:24]; h_Rd=basic_data[31:16]; w_Rd=basic_data[31: 0];end
            3'b100:begin b_Rd=basic_data[39:32]; h_Rd=basic_data[47:32]; w_Rd=basic_data[63:32];end
            3'b101:begin b_Rd=basic_data[47:40]; h_Rd=basic_data[47:32]; w_Rd=basic_data[63:32];end
            3'b110:begin b_Rd=basic_data[55:48]; h_Rd=basic_data[63:48]; w_Rd=basic_data[63:32];end
            3'b111:begin b_Rd=basic_data[63:56]; h_Rd=basic_data[63:48]; w_Rd=basic_data[63:32];end
        endcase
    end

    wire w;
    assign w=~MemOp[2];
    always @(*) begin
        case(MemOp[1:0])
            2'b00: data={{56{b_Rd[7]&&w}},b_Rd};
            2'b01: data={{48{h_Rd[15]&&w}},h_Rd};
            2'b10: data={{32{w_Rd[31]&&w}},w_Rd};
            default:data=basic_data;
        endcase
    //    $display("addr=%h,addr_low=%b",addr,addr[2:0]);
    //    $display("b=%h,h=%h,w=%h,q=%h,final=%h",b_Rd,h_Rd,w_Rd,basic_data,data);
    end
endmodule