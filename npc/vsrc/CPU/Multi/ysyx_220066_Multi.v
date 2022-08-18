module ysyx_220066_Multi(
    input clk,block,valid_in,
    output ready,
    output reg valid,

    input [63:0] rs1,
    input [63:0] rs2,
    input [1:0] ALUctr,
    input is_w;
    output reg [63:0] result
);
    wire [63:0] mul_low;
    assign mul_low=src1*src2;
    wire [127:0] mul_high;
    assign mul_high=({{64{src1[63]}},src1}*{{64{src2[63]}},src2});
    wire [127:0] mul_hsu;
    assign mul_hsu=({{64{src1[63]}},src1}*{64'h0,src2});
    wire [127:0] mul_hu;
    assign mul_hu=({64'h0,src1}*{64'h0,src2});

    assign ready=~(block&&valid);

    always @(posedge clk) begin
        if(rst) valid<=0;
        else if(~block&&valid) valid<=valid_in;
    end

    always @(posedge clk) if(~(block&&valid)) case (ALUctr)
        2'b00:result={is_w?{32{mul_low[31]}}:mul_low[63:32],mul_low[31:0]};
        2'b01:result=mul_high[127:64];
        2'b10:result=mul_hsu[127:64];
        2'b11:result=mul_hu[127:64];
    endcase

    always @(*) begin
        //
    end

endmodule