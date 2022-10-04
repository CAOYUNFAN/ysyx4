//`timescale 1ns/1ps
module ysyx_040066_top(
  input clk,rst,

  output ins_req,ins_burst,
  output [63:0] ins_addr,
  input ins_ready,ins_err,ins_last,
  input [63:0] ins_data,

  output rd_req,rd_burst,
  output [2:0] rd_len,
  output [63:0] rd_addr,
  input rd_ready,rd_err,rd_last,
  input [63:0] rd_data,

  output wr_req,wr_burst,
  output [2:0] wr_len,
  output [7:0] wr_mask,
  output [63:0] wr_addr,
  input wr_ready,wr_err,
  output [511:0] wr_data,

  input [127:0] ram_Q [7:0],
  output [127:0] ram_D [7:0],
  output [127:0] ram_BWEN [1:0],
  output [5:0] ram_A [1:0],
  output ram_WEN [1:0]
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
  wire error,done,valid;
  wire [63:0] pc_nxt,pc_m;

  ysyx_040066_cpu cpu(
    .clk(clk),.rst(rst),
    .pc_nxt(pc_nxt),
    .pc_rd(pc_rd),.instr_rd(instr),.instr_valid(instr_valid&&d_ready),.instr_error(instr_error),
    .addr(addr),.wr_mask(wr_mask),.MemRd(MemRd),.MemWr(MemWr),
    .data_valid(data_valid),.data_error(data_error),
    .data_Rd(data_Rd),.data_Wr(data_Wr),.wr_len(wr_len),
    .error(error),.done(done),.out_valid(valid),.fence_i(fence_i)
  );
  assign rd_len=wr_len;
  wire [63:0] instr_line;
  wire [31:0] icache_addr;
  wire icahce_req,icache_ready;//unused
  wire [511:0] icache_data;//unused
  ysyx_040066_cache_top icache(
    .clk(clk),.rst(rst),.force_update(fence_i),

    .valid(1),.op(0),
    .tag(pc_rd[31:11]),.index(pc_rd[10:6]),.offset(pc_rd[5:3]),
    .wstrb(8'b0),.wdata(64'h0),.fence(1'b0),
    .ok(instr_valid),.ready(icache_ready),.rdata(instr_line),.rw_error(instr_error),

    .addr(icache_addr),.rd_req(ins_req),.rd_ready(ins_ready),.rd_last(ins_last),.rd_error(ins_err),
    .rd_data(ins_data),.wr_req(icahce_req),.wr_data(icache_data),.wr_ready(1'b0),.wr_error(1'b0),

    .ram_Q(ram_Q[3:0]),.ram_D(ram_D[3:0]),.ram_BWEN(ram_BWEN[0]),.ram_A(ram_A[0]),.ram_WEN(ram_WEN[0])
  );
  reg pc_2;always@(posedge clk) pc_2<=pc_rd[2];
  assign instr=pc_2?instr_line[63:32]:instr_line[31:0];
  assign ins_burst=~pc_rd[31];
  assign ins_addr=ins_burst?pc_rd:{32'h0,icache_addr};

  wire [31:0] dcache_addr;
  ysyx_040066_cache_top dcache(
    .clk(clk),.rst(rst),.force_update(1'b0),

    .valid(MemRd||MemWr),.op(MemWr),
    .tag(addr[31:11]),.index(addr[10:6]),.offset(addr[5:3]),
    .wstrb(wr_mask),.wdata(data_Wr),.ok(data_valid),.ready(d_ready),
    .rdata(data_Rd),.rw_error(data_error),.fence(fence_i),
    
    .addr(dcache_addr),
    .rd_req(rd_req),.rd_ready(rd_ready),.rd_last(rd_last),.rd_error(rd_err),.rd_data(rd_data),
    .wr_req(wr_req),.wr_data(wr_data),.wr_ready(wr_ready),.wr_error(wr_err),

    .ram_Q(ram_Q[7:4]),.ram_D(ram_D[7:4]),.ram_BWEN(ram_BWEN[1]),.ram_A(ram_A[1]),.ram_WEN(ram_WEN[1])
  );

  assign rd_burst=~dcache_addr[31];
  assign wr_burst=~dcache_addr[31];
  assign rd_addr=rd_burst?addr:{32'h0,dcache_addr};
  assign wr_addr=rd_addr;

`ifdef WORKBENCH
  reg [63:0] dbg_regs [31:0];
  import "DPI-C" function void set_gpr_ptr(input logic [63:0] a []);
  initial set_gpr_ptr(dbg_regs);
  import "DPI-C" function void set_pc_ptr(input logic [63:0] pc []);
  initial set_pc_ptr(pc_nxt);
  import "DPI-C" function void set_pc_m_ptr(input logic [63:0] pc_m []);
  initial set_pc_m_ptr(pc_m);
  import "DPI-C" function void status_now(input longint status);
  always @(*) status_now({61'b0,error,done,valid});
  integer i;
  always @(*) begin
    for(i=1;i<32;i=i+1) dbg_regs[i]=cpu.module_regs.module_regs.rf[i];
    dbg_regs[0]=0;
//    if(MemWr&&clk)$display("Write to:addr=%h,data=%x,help=%h,real=%h,wmask=%b",addr,data_Wr,data_Wr_help,data_Wr_data,wmask);
  end
  `endif
  assign pc_m=cpu.module_m.nxtpc;
endmodule
