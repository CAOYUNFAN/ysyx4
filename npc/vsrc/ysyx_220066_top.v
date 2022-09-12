`timescale 1ns/1ps
module ysyx_220066_top(
  output [63:0] pc_nxt,
  input clk,rst,

  output ins_req,ins_burst,
  output [63:0] ins_addr,
  input ins_ready,ins_err,
  input [511:0] ins_data,

  output rd_req,rd_burst,
  output [2:0] rd_len,
  output [63:0] rd_addr,
  input rd_ready,rd_err,
  input [511:0] rd_data,

  output wr_req,wr_burst,
  output [2:0] wr_len,
  output [7:0] wr_mask,
  output [63:0] wr_addr,
  input wr_ready,wr_err,
  output [511:0] wr_data,

  output reg [63:0] dbg_regs [31:0],
  output reg [63:0] mepc,
  output reg [63:0] mstatus,
  output reg [63:0] mcause,
  output reg [63:0] mtvec,

  output error,done,valid
);
  wire MemWr,MemRd;
  wire [63:0] addr;
  wire [63:0] data_Rd;
  wire [63:0] pc_rd;
  wire [63:0] data_Wr;
  wire [31:0] instr;
  wire instr_valid,instr_error;
  wire data_valid,data_error;
  wire fence_i,d_ready;

  ysyx_220066_cpu cpu(
    .clk(clk),.rst(rst),
    .pc_nxt(pc_nxt),
    .pc_rd(pc_rd),.instr_rd(instr),.instr_valid(instr_valid&&d_ready),.instr_error(instr_error),
    .addr(addr),.wr_mask(wr_mask),.MemRd(MemRd),.MemWr(MemWr),
    .data_valid(data_valid),.data_error(data_error),
    .data_Rd(data_Rd),.data_Wr(data_Wr),.wr_len(wr_len),
    .error(error),.done(done),.out_valid(valid),.fence_i(fence_i)
  );

  wire [63:0] instr_line;
  wire [31:0] icache_addr;
  ysyx_220066_cache icache(
    .clk(clk),.rst(rst),.force_update(fence_i),

    .valid(1),.op(0),
    .tag(pc_rd[31:11]),.index(pc_rd[10:6]),.offset(pc_rd[5:3]),
    .wstrb(8'b0),.wdata(64'h0),.fence(1'b0),
    .ok(instr_valid),.ready(),.rdata(instr_line),.rw_error(instr_error),

    .addr(icache_addr),.rd_req(ins_req),.rd_ready(ins_ready),.rd_error(ins_err),
    .rd_data(ins_data),.wr_req(),.wr_data(),.wr_ready(1'b0),.wr_error(1'b0)
  );
  reg pc_2;always@(posedge clk) pc_2<=pc_rd[2];
  assign instr=pc_2?instr_line[63:32]:instr_line[31:0];
  assign ins_addr=pc_rd[31]?pc_rd:{32'h0,icache_addr};
  assign ins_burst=pc_rd[31];

  wire [31:0] dcache_addr;
  ysyx_220066_cache dcache(
    .clk(clk),.rst(rst),.force_update(1'b0),

    .valid(MemRd||MemWr),.op(MemWr),
    .tag(addr[31:11]),.index(addr[10:6]),.offset(addr[5:3]),
    .wstrb(wr_mask),.wdata(data_Wr),.ok(data_valid),.ready(d_ready),
    .rdata(data_Rd),.rw_error(data_error),.fence(fence_i),
    
    .addr(dcache_addr),
    .rd_req(rd_req),.rd_ready(rd_ready),.rd_error(rd_err),.rd_data(rd_data),
    .wr_req(wr_req),.wr_data(wr_data),.wr_ready(wr_ready),.wr_error(wr_err)
  );

  assign rd_burst=dcache_addr[31];
  assign wr_burst=dcache_addr[31];
  assign rd_addr=rd_burst?addr:{32'h0,dcache_addr};
  assign wr_addr=rd_addr;

/*  ysyx_220066_imem imem(
    .clk(clk),.rst(rst),
    .pc(pc_rd),.instr(instr),
    .error(instr_error),.valid(instr_valid)
  );

  ysyx_220066_memwr memwr(
    .clk(clk),.rst(rst),.addr(addr),.wmask(wr_mask),
    .data(data_Wr),.MemWr(MemWr)
  );

  ysyx_220066_dmem_rd dmemrd(
    .clk(clk),.rst(rst),.MemRd(MemRd),
    .addr(addr),.data(data_Rd),
    .error(data_Rd_error),.valid(data_Rd_valid)
  );*/

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
