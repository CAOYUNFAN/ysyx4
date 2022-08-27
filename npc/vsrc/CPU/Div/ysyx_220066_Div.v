module ysyx_220066_Div(
    input clk,rst,block,valid_in,
    output ready,valid,
    
    input [63:0] src1_in,
    input [63:0] src2_in,
    input [63:0] nxtpc_in,
    input [4:0] rd_in,
    input [1:0] ALUctr_in,
    input is_w_in,error_in,

    output valid_part,
    output [4:0] rd_part,

    output [63:0] result,
    output [4:0] rd
);
    wire [63:0] nxtpc;
    wire error;

    reg [63:0] src1_native;
    reg [63:0] src2_native;
    reg [63:0] nxtpc_native;
    reg [4:0] rd_native;
    reg [1:0] ALUctr_native;
    reg is_w_native,valid_native,error_native;

    reg [63:0] result_middle;
    reg [63:0] nxtpc_middle;
    reg [4:0] rd_middle;
    reg error_middle,valid_middle;

    always @(posedge clk) if(~block) begin
        src1_native<=src1_in;
        src2_native<=src2_in;
        nxtpc_native<=nxtpc_in;
        rd_native<=rd_in;
        ALUctr_native<=ALUctr_in;
        is_w_native<=is_w_in;error_native<=error_in;
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

    always @(posedge clk) begin
        if(rst) begin
            valid_native<=0;
            valid_middle<=0;
        end else if(~block) begin
            valid_native<=valid_in;
            valid_middle<=valid_native;
        end
    end

    always @(posedge clk) if(~block) begin 
        case (ALUctr_native)
            2'b00:result_middle<=is_w_native?{{32{div[31]}},div}:$signed(src1_native)/$signed(src2_native);
            2'b01:result_middle<=is_w_native?{{32{div_u[31]}},div_u}:src1_native/src2_native;
            2'b10:result_middle<=is_w_native?{{32{rem[31]}},rem}:$signed(src1_native)%$signed(src2_native);
            2'b11:result_middle<=is_w_native?{{32{rem_u[31]}},rem_u}:src1_native%src2_native;
        endcase
        nxtpc_middle<=nxtpc_native;
        error_middle<=error_native||(src2_native==64'b0);
        rd_middle<=rd_native;
    end

    assign valid_part=valid_native;
    assign rd_part=rd_native;

    assign result=result_middle;
    assign valid=valid_middle;
    assign nxtpc=nxtpc_middle;
    assign rd=rd_middle;
    assign error=error_middle;

    always @(*) begin

    end
endmodule
