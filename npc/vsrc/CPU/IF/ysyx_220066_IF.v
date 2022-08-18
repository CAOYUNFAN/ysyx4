module ysyx_220066_IF (
    input clk,rst,block,
    output reg valid,

    input is_jmp,
    input [63:0] nxtpc,
    output [63:0] pc_instr,
    output reg [63:0] pc,
);
    always @(posedge clk) begin
        if(rst) begin
            pc_instr <= 64'h80000000;
            valid <= 0;
        end else if(block&&valid) begin 
            pc <= pc;
            valid <= 1;
        end else begin
            pc <= is_jmp ? nxtpc : pc+4;
            valid <= 1;
        end
    end

    assign pc_instr=is_jmp ? nxtpc : pc+4;
endmodule
