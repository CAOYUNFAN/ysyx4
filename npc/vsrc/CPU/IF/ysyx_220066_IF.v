module ysyx_220066_IF (
    input clk,rst,block,

    input is_jmp,
    input [63:0] nxtpc,
    input [63:0] old_pc,
    output reg [63:0] native_pc
);
    wire valid;
    wire [63:0] pc;
    always @(posedge clk) begin
        if(rst) native_pc<=64'h8000_0000;
        else if(block) native_pc<=old_pc;
        else native_pc<=is_jmp?nxtpc:native_pc+4;
    end

    assign pc=native_pc;
    assign valid=~is_jmp;

    always @(*) begin
        `ifdef INSTR
        if(~rst&&~clk) $display("IF:pc=%h,valid=%b,block=%b",pc,valid,block);
        `endif
    end
endmodule
