module ysyx_040066_Div(
    input clk,rst,

    input [63:0] src1_in,
    input [63:0] src2_in,
    input is_w,
    input [1:0] ALUctr_in,
    input in_valid,
    output reg in_ready,
    output out_valid,
    output [63:0] result
);
    //prework
    wire [63:0] src1,src2,x_abs,y_abs;
    wire div_signed,x_sign,y_sign;
    assign div_signed=~ALUctr_in[0];
    assign src1={is_w?{32{src1_in[31]&&div_signed}}:src1_in[63:32],src1_in[31:0]};
    assign src2={is_w?{32{src2_in[31]&&div_signed}}:src2_in[63:32],src2_in[31:0]};

    assign x_sign=src1[63]&&div_signed;
    assign y_sign=src2[63]&&div_signed;
    assign x_abs=x_sign?(~src1+64'b1):src1;
    assign y_abs=y_sign?(~src2+64'b1):src2;
    //control_regs
    reg doing;
    reg [5:0] count;//in_ready
    assign out_valid = doing && in_ready;
    wire ready_to_doing;
    assign ready_to_doing = in_ready&&in_valid;

    always @(posedge clk) begin
        if(rst||(&count)) in_ready<=1;
        else if(ready_to_doing) in_ready<=0;
    end

    always @(posedge clk) begin
        if(rst) doing<=0;
        else if(ready_to_doing) doing<=1;
        else if(out_valid) doing<=0;
    end

    always @(posedge clk) begin
        if(rst||ready_to_doing) count<=6'b0;
        else if(doing) count<=count+6'b1;
    end
    //calculate regs
    reg dividend_s,divisor_s,aluctr;

    always @(posedge clk) if(ready_to_doing) begin
        dividend_s<=x_sign;
        divisor_s<=y_sign;
        aluctr<=ALUctr_in[1];
    end

    reg [127:0] dividend;
    reg [63:0] divisor;

    wire sub_cout;
    wire [63:0] sub_result;
    assign {sub_cout,sub_result}=dividend[127:63]-{1'b0,divisor};

    always @(posedge clk) begin
        if(ready_to_doing) begin
            dividend <= {64'b0,x_abs};
            divisor <= y_abs;
        end else if(doing) begin
            dividend <= {sub_cout?dividend[126:63]:sub_result[63:0],dividend[62:0],~sub_cout};
        end
    end

    wire [63:0] qutient,remain,qutient_real,remain_real;
    assign {remain,qutient}=dividend;
    assign qutient_real=(dividend_s^divisor_s)?-qutient:qutient;
    assign remain_real=dividend_s?-remain:remain;
    assign result=aluctr?remain_real:qutient_real;

    always @(*) begin
        `ifdef INSTR
        //if(~rst&&~clk)$display("DIV:count=%h,the long=%h",count,dividend);
        `endif
    end
endmodule