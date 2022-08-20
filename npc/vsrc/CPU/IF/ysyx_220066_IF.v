module ysyx_220066_IF (
    input clk,rst,block,
    output valid,

    input is_jmp,
    input [63:0] nxtpc,
    output [63:0] pc,
    output reg [63:0] native_pc,
);
    always @(posedge clk) begin
        if(rst) native_pc<=64'b8000_0000;
        else if(block) native_pc<=native_pc;
        else native_pc<=is_jmp?nxtpc:pc+4;
    end

    assign pc=native_pc;
    assign valid=~is_jmp&&instr_valid&&valid_in;
endmodule
