module ysyx_220066_IF (
    input clk,rst,block,id_block,

    input is_jmp,
    input [63:0] nxtpc,
    output reg [63:0] native_pc
);
    wire valid;
    wire [63:0] pc;
    always @(posedge clk) begin
        if(rst) native_pc<=64'h3000_0000;
        else if(block) native_pc<=native_pc;
        else native_pc<=is_jmp?nxtpc:id_block?native_pc:native_pc+4;
    end

    assign pc=native_pc;
    assign valid=~is_jmp;

    always @(*) begin
        `ifdef INSTR
        if(~rst&&~clk) $display("IF:pc=%h,valid=%b,block=%b",pc,valid,block);
        `endif
    end
endmodule
