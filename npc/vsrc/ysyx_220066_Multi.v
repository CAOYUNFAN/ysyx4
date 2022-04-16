module ysyx_220066_Multi(
    input [63:0] src1,
    input [63:0] src2,
    input [2:0] ALUctr,
    output reg [63:0] result
);
    wire [63:0] mul_low;
    assign mul_low=src1*src2;
    wire [127:0] mul_high;
    assign mul_high={{64{src1[63]}},src1}*{{64{src2[63]}},src2};
    wire [127:0] mul_hsu;
    assign mul_hsu={{64{src1[63]}},src1}*{64'h0,src2};
    wire [127:0] mul_hu;
    assign mul_hu={64'h0,src1}*{64'h0,src2};
    wire [63:0] div;
    assign div=($signed(src1))/($signed(src2));
    wire [63:0] div_u;
    assign div_u=src1/src2;
    wire [63:0] rem;
    assign rem=($signed(src1))%($signed(src2));
    wire [63:0] rem_u;
    assign rem_u=src1%src2;
    always @(*) begin
        case(ALUctr)
            3'b000:result=mul_low;
            3'b001:result=mul_high[127:64];
            3'b010:result=mul_hsu[127:64];
            3'b011:result=mul_hu[127:64];
            3'b100:result=div;
            3'b101:result=div_u;
            3'b110:result=rem;
            3'b111:result=rem_u;
        endcase
    end
endmodule
