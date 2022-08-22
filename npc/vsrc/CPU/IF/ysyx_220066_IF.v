module ysyx_220066_IF (
    input clk,rst,block,

    input is_jmp,
    input [63:0] nxtpc,
    output reg [63:0] native_pc
);
    wire valid;
    wire [63:0] pc;
    always @(posedge clk) begin
        if(rst) native_pc<=64'h8000_0000;
        else if(block) native_pc<=native_pc;
        else native_pc<=is_jmp?nxtpc:pc+4;
    end

    assign pc=native_pc;
    assign valid=~is_jmp;
endmodule
