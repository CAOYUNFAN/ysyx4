module ysyx_220066_IF (
    input clk,rst,block,
    output reg valid,

    input is_jmp,
    input [63:0] nxtpc,
    output reg [63:0] pc,
    output [31:0] instr
);
    import "DPI-C" function void data_read(
        input longint raddr,input byte memrd, output longint rdata
    );

    reg [63:0] instr_long;
    assign instr=pc[2]?instr_long[63:32]:instr_long[31:0];

    always @(posedge clk) begin
        if(rst) begin
            pc <= 64'h80000000;
            valid <= 0;
            instr_long <= 64'h114514;
        end else if(block&&valid) begin 
            pc <= pc;
            valid <= 1;
            instr_long <= instr_long;
        end else begin
            pc <= is_jmp ? nxtpc : pc+4;
            valid <= 1;
            data_read(is_jmp ? nxtpc : pc + 4 , instr_long);
        end
    end
endmodule
