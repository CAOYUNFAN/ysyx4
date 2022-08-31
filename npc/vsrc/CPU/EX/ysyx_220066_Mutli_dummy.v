module ysyx_220066_Multi_dummy(
    input [63:0] src1,
    input [63:0] src2,
    input [2:0] ALUctr,
    input is_w,
    output reg [63:0] result,
    output error
);
    /*wire [63:0] mul_low;
    assign mul_low=src1*src2;
    wire [127:0] mul_high;
    assign mul_high=({{64{src1[63]}},src1}*{{64{src2[63]}},src2});
    wire [127:0] mul_hsu;
    assign mul_hsu=({{64{src1[63]}},src1}*{64'h0,src2});
    wire [127:0] mul_hu;
    assign mul_hu=({64'h0,src1}*{64'h0,src2});*/

    wire [31:0] div;
    assign div=($signed(src1[31:0]))/($signed(src2[31:0]));
    wire [31:0] div_u;
    assign div_u=src1[31:0]/src2[31:0];
    wire [31:0] rem;
    assign rem=($signed(src1[31:0]))%($signed(src2[31:0]));
    wire [31:0] rem_u;
    assign rem_u=src1[31:0]%src2[31:0];

    always @(*) case(ALUctr)
        /*3'b000:result={is_w?{32{mul_low[31]}}:mul_low[63:32],mul_low[31:0]};
        3'b001:result=mul_high[127:64];
        3'b010:result=mul_hsu[127:64];
        3'b011:result=mul_hu[127:64];*/
        3'b000,3'b001,3'b010,3'b011:result=64'h1145141919810;
        3'b100:result=is_w?{{32{div[31]}},div}:$signed(src1)/$signed(src2);
        3'b101:result=is_w?{{32{div_u[31]}},div_u}:src1/src2;
        3'b110:result=is_w?{{32{rem[31]}},rem}:$signed(src1)%$signed(src2);
        3'b111:result=is_w?{{32{rem_u[31]}},rem_u}:src1%src2;
    endcase

    assign error=ALUctr[2]&&(src2==64'h0);
endmodule