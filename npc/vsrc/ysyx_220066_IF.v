module ysyx_220066_IF (
    input [63:0] nxtpc,
    input clk,rst,
    output reg [63:0] pc
);
    always @(posedge clk) begin
        if(rst) pc<=64'h80000000;
        else begin
            pc<=nxtpc;
//            $display("nxtpc=%x",nxtpc);
        end
    end
endmodule
