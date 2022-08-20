module ysyx_220066_Multi(
    input clk,block,valid_in,error_in,
    output ready,
    output valid,

    input [63:0] src1_in,
    input [63:0] src2_in,
    input [63:0] pc_in,
    input [4:0] rd_in,
    input [1:0] ALUctr_in,
    input is_w_in,done_in,

    output valid_part,
    output [4:0] rd_part,

    output [63:0] result,
    output [63:0] pc,
    output [4:0] rd,
    output error,done
);
    reg [63:0] src1_native;
    reg [63:0] src2_native;
    reg [63:0] pc_native;
    reg [4:0] rd_native;
    reg [1:0] ALUctr_native;
    reg is_w_native,valid_native,error_native,done_native;

    reg [63:0] result_middle;
    reg [63:0] pc_middle;
    reg [4:0] rd_middle;
    reg error_middle,valid_middle,done_middle;

    always @(posedge clk) if(~block) begin
        src1_native<=src1_in;
        src2_native<=src2_in;
        pc_native<=pc_in;
        rd_native<=rd_in;
        ALUctr_native<=ALUctr_in;
        is_w_native<=is_w_in;error_native<=error_in;
        done_native<=done_in;
    end

    always @(posedge clk) begin
        valid_native<=~rst&&(block?valid_native:valid_in);
        valid_middle<=~rst&&(block?valid_middle:valid_native);
    end
    assign ready=~block;

    wire [63:0] mul_low;
    assign mul_low=src1_native*src2_native;
    wire [127:0] mul_high;
    assign mul_high=({{64{src1_native[63]}},src1_native}*{{64{src2_native[63]}},src2_native});
    wire [127:0] mul_hsu;
    assign mul_hsu=({{64{src1_native[63]}},src1_native}*{64'h0,src2_native});
    wire [127:0] mul_hu;
    assign mul_hu=({64'h0,src1_native}*{64'h0,src2_native});

    always @(posedge clk) if(~block) begin
        case (ALUctr_native)
            2'b00:result_middle<={is_w_native?{32{mul_low[31]}}:mul_low[63:32],mul_low[31:0]};
            2'b01:result_middle<=mul_high[127:64];
            2'b10:result_middle<=mul_hsu[127:64];
            2'b11:result_middle<=mul_hu[127:64];
        endcase
        error_middle<=error_native;
        pc_middle<=pc_native;
        rd_middle<=rd_native;
        done_middle<=done_native;
    end

    assign valid_part=valid_native;
    assign rd_part=rd_native;

    assign result=result_middle;
    assign valid=valid_middle;
    assign pc=pc_middle;
    assign rd=rd_middle;
    assign error=error_middle;
    assign done=done_middle;

    always @(*) begin
        //
    end

endmodule
