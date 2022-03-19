module ysyx_220066_IF (
    input [63:0] nxtpc,
    input clk,rst,
    output reg [63:0] pc
);
    always @(posedge clk) begin
        if(rst) pc<=64'h0;
        else begin
            nxtpc<=pc;
        end
    end
endmodule