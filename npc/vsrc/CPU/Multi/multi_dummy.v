module multi_dummy(
    input clk,block,
    input [63:0] src1_in,//clk0
    input [63:0] src2_in,//clk0
    input [1:0] ALUctr_in,//clk0
    input [1:0] ALUctr,//clk1
    input is_w,//clk1

    output [63:0] result 
);
    reg [63:0] src1,src2;
    always @(posedge clk) if(~block) begin
        src1<=src1_in;
        src2<=src2_in;
    end

    wire [63:0] mul_low;
    assign mul_low=src1*src2;
    wire [127:0] mul_high;
    assign mul_high=({{64{src1[63]}},src1}*{{64{src2[63]}},src2});
    wire [127:0] mul_hsu;
    assign mul_hsu=({{64{src1[63]}},src1}*{64'h0,src2});
    wire [127:0] mul_hu;
    assign mul_hu=({64'h0,src1}*{64'h0,src2});

    reg [63:0] result_middle;

    always @(posedge clk) case(ALUctr) 
        2'b00:result_middle <= {is_w?{32{mul_low[31]}}:mul_low[63:32],mul_low[31:0]};
        2'b01:result_middle <= mul_high[127:64];
        2'b10:result_middle <= mul_hsu[127:64];
        2'b11:result_middle <= mul_hu[127:64];
    endcase

    assign result=result_middle;
endmodule