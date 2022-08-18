module ysyx_220066_Div(
    input clk,rst,block,valid_in,
    output ready,
    output reg valid,
    
    input [63:0] src1,
    input [63:0] src2,
    input [1:0] ALUctr,
    input is_w,
    output reg [63:0] result
);
    wire [31:0] div;
    assign div=($signed(src1[31:0]))/($signed(src2[31:0]));
    wire [31:0] div_u;
    assign div_u=src1[31:0]/src2[31:0];
    wire [31:0] rem;
    assign rem=($signed(src1[31:0]))%($signed(src2[31:0]));
    wire [31:0] rem_u;
    assign rem_u=src1[31:0]%src2[31:0];

    assign ready=~(block&&valid);
    always @(posedge clk) begin
        if(rst) valid<=0;
        else if(~(block&&valid)) valid<=valid_in;
    end

    always @(posedge clk) if(~(block&&valid)) case (ALUctr)
        2'b00:result=is_w?{{32{div[31]}},div}:$signed(src1)/$signed(src2);
        2'b01:result=is_w?{{32{div_u[31]}},div_u}:src1/src2;
        2'b10:result=is_w?{{32{rem[31]}},rem}:$signed(src1)%$signed(src2);
        2'b11:result=is_w?{{32{rem_u[31]}},rem_u}:src1%src2;
    endcase
endmodule