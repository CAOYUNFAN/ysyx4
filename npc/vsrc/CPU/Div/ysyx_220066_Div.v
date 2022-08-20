module ysyx_220066_Div(
    input clk,rst,block,valid_in,
    output ready,valid,
    
    input [63:0] src1_in,
    input [63:0] src2_in,
    input [63:0] pc_in,
    input [4:0] rd_in,
    input [1:0] ALUctr_in,
    input is_w_in,error_in,done_in,

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

    wire [31:0] div;
    assign div=($signed(src1_native[31:0]))/($signed(src2_native[31:0]));
    wire [31:0] div_u;
    assign div_u=src1_native[31:0]/src2_native[31:0];
    wire [31:0] rem;
    assign rem=($signed(src1_native[31:0]))%($signed(src2_native[31:0]));
    wire [31:0] rem_u;
    assign rem_u=src1_native[31:0]%src2_native[31:0];

    assign ready=~block;

    reg [63:0] pc_middle;
    reg error_middle;
    always @(posedge clk) begin
        if(rst) valid<=0;
        else if(~block) valid<=valid_in;
    end

    always @(posedge clk) if(~block) begin 
        case (ALUctr)
            2'b00:result_middle<=is_w?{{32{div[31]}},div}:$signed(src1_native)/$signed(src2_native);
            2'b01:result_middle<=is_w?{{32{div_u[31]}},div_u}:src1_native/src2_native;
            2'b10:result_middle<=is_w?{{32{rem[31]}},rem}:$signed(src1_native)%$signed(src2_native);
            2'b11:result_middle<=is_w?{{32{rem_u[31]}},rem_u}:src1_native%src2_native;
        endcase
        pc_middle<=pc_native;
        error_middle<=error_native||(src2_native==64'b0);
        rd_middle<=rd_middle;
        error<=error_middle;
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

    end
endmodule
