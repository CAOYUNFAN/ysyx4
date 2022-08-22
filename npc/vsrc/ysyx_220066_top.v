module ysyx_220066_top(
  output [63:0] pc_done,
//  input [63:0] instr_data,
  input clk,rst,
  //output [63:0] addr,
  //output reg [63:0] data_Wr_data,

  output reg [63:0] dbg_regs [31:0],
  output reg [63:0] mepc,
  output reg [63:0] mstatus,
  output reg [63:0] mcause,
  output reg [63:0] mtvec,

  output error,done,valid
);
  wire MemWr,MemRd;
  wire [63:0] addr;
  wire [2:0] MemOp;
  wire [63:0] data_Rd;
  wire [63:0] pc_rd;
  wire [63:0] data_Wr;
  wire [31:0] instr;
  wire instr_valid,instr_error;
  wire data_Rd_valid,data_Rd_error;

/*  assign data_Wr_data[ 7: 0]=wmask[0]?data_Wrr[ 7: 0]:data_Wr_help[ 7: 0];
  assign data_Wr_data[15: 8]=wmask[1]?data_Wrr[15: 8]:data_Wr_help[15: 8];
  assign data_Wr_data[23:16]=wmask[2]?data_Wrr[23:16]:data_Wr_help[23:16];
  assign data_Wr_data[31:24]=wmask[3]?data_Wrr[31:24]:data_Wr_help[31:24];
  assign data_Wr_data[39:32]=wmask[4]?data_Wrr[39:32]:data_Wr_help[39:32];
  assign data_Wr_data[47:40]=wmask[5]?data_Wrr[47:40]:data_Wr_help[47:40];
  assign data_Wr_data[55:48]=wmask[6]?data_Wrr[55:48]:data_Wr_help[55:48];
  assign data_Wr_data[63:56]=wmask[7]?data_Wrr[63:56]:data_Wr_help[63:56];
*/
  ysyx_220066_cpu cpu(
    .clk(clk),.rst(rst),
    .pc_done(pc_done),
    .pc_rd(pc_rd),.instr(instr),.instr_valid(instr_valid),.instr_error(instr_error),
    .addr(addr),.MemOp(MemOp),.MemRd(MemRd),.MemWr(MemWr),
    .data_Rd_valid(data_Rd_valid),.data_Rd_error(data_Rd_error),
    .data_Rd(data_Rd),.data_Wr(data_Wr),.error(error),.done(done),.out_valid(valid)
  );


  ysyx_220066_imem imem(
    .clk(clk),.rst(rst),
    .pc(pc_rd),.instr(instr),
    .error(data_Rd_error),.valid(data_Rd_valid)
  );

  ysyx_220066_dmem_rd dmemrd(
    .clk(clk),.rst(rst),.MemRd(MemRd),
    .addr(addr),.MemOp(MemOp),.data(data_Rd),
    .error(data_Rd_error),.valid(data_Rd_valid)
  );

  ysyx_220066_memwr memwr(
    .clk(clk),.rst(rst),.addr(addr),
    .MemOp(MemOp),.data(data_Wr),.MemWr(MemWr)
  );

  integer i;
  always @(*) begin
    for(i=1;i<32;i=i+1) dbg_regs[i]=cpu.module_regs.module_regs.rf[i];
    dbg_regs[0]=0;
//    if(MemWr&&clk)$display("Write to:addr=%h,data=%x,help=%h,real=%h,wmask=%b",addr,data_Wr,data_Wr_help,data_Wr_data,wmask);
    mepc=cpu.module_csr.mepc;
    mstatus=cpu.module_csr.mstatus;
    mcause=cpu.module_csr.mcause;
    mtvec=cpu.module_csr.mtvec;
  end
endmodule
