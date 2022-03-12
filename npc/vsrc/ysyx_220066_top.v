module ysyx_220066_top(
  output [63:0] pc,
  input [31:0] instr,
  input clk
);
  wire [63:0] imm;
  wire [4:0] rs1;
  wire [4:0] rd;
  wire [63:0] result;
  reg [63:0] pcc;
  ysyx_220066_ID ysyx_220066_id(.instr(instr),.rs1(rs1),.rd(rd),.imm(imm));
  ysyx_220066_Regs ysyx_220066_regs(.clk(clk),.wdata(result),.waddr(rd),.wen(1));
  assign result=ysyx_220066_regs.rf[rs1]+imm;
  initial begin
    pcc=64'h80000000;
  end
  always @(posedge clk) begin
    pcc<=pcc+4;
  end
  assign pc=pcc;
endmodule
