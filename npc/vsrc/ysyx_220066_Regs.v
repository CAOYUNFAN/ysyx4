module ysyx_220066_Regs #(ADDR_WIDTH = 5, DATA_WIDTH = 64) (
  input clk,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input wen
);
  reg [DATA_WIDTH-1:0] rf [31:0];
  always @(posedge clk) begin
    if (wen) begin 
      $display("in:addr=%h,data=%h",waddr,wdata);
      rf[waddr] <= wdata;
    end
  end
endmodule
