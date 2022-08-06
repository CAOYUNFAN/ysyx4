module ysyx_220066_top(
  output [63:0] pc,
  input [63:0] instr_data,
  input clk,rst,
  output [63:0] addr,
  //output reg [63:0] data_Wr_data,

  output reg [63:0] dbg_regs [31:0],
  output error,done,status
);
  wire MemWr,MemRd;
  wire [31:0] instr;
  assign instr=pc[2]?instr_data[63:32]:instr_data[31:0];
  wire [2:0] MemOp;
  reg [63:0] data_Rd;
  reg [7:0] b_Rd;reg [15:0] h_Rd;reg [31:0] w_Rd;

  import "DPI-C" function void data_read(
    input longint raddr,input byte memrd, output longint rdata
  );

  reg [63:0] data_Rd_data;
  always @(*) begin
    data_read(addr,{7'b0,MemRd&!rst},data_Rd_data);
  end

//  wire [63:0] data_Wr_help;
//  assign data_Wr_help=data_Rd_data;

  always @(*) begin
    case(addr[2:0])
      3'b000:begin b_Rd=data_Rd_data[ 7: 0]; h_Rd=data_Rd_data[15: 0]; w_Rd=data_Rd_data[31: 0];end
      3'b001:begin b_Rd=data_Rd_data[15: 8]; h_Rd=data_Rd_data[15: 0]; w_Rd=data_Rd_data[31: 0];end
      3'b010:begin b_Rd=data_Rd_data[23:16]; h_Rd=data_Rd_data[31:16]; w_Rd=data_Rd_data[31: 0];end
      3'b011:begin b_Rd=data_Rd_data[31:24]; h_Rd=data_Rd_data[31:16]; w_Rd=data_Rd_data[31: 0];end
      3'b100:begin b_Rd=data_Rd_data[39:32]; h_Rd=data_Rd_data[47:32]; w_Rd=data_Rd_data[63:32];end
      3'b101:begin b_Rd=data_Rd_data[47:40]; h_Rd=data_Rd_data[47:32]; w_Rd=data_Rd_data[63:32];end
      3'b110:begin b_Rd=data_Rd_data[55:48]; h_Rd=data_Rd_data[63:48]; w_Rd=data_Rd_data[63:32];end
      3'b111:begin b_Rd=data_Rd_data[63:56]; h_Rd=data_Rd_data[63:48]; w_Rd=data_Rd_data[63:32];end
    endcase
  end
  always @(*) begin
    case(MemOp)
      3'b100: data_Rd={56'h0,b_Rd};
      3'b000: data_Rd={{56{b_Rd[7]}},b_Rd};
      3'b101: data_Rd={48'h0,h_Rd};
      3'b001: data_Rd={{48{h_Rd[15]}},h_Rd};
      3'b110: data_Rd={32'h0,w_Rd};
      3'b010: data_Rd={{32{w_Rd[31]}},w_Rd};
      default:data_Rd=data_Rd_data;
    endcase
//    $display("addr=%h,addr_low=%b",addr,addr[2:0]);
//    $display("b=%h,h=%h,w=%h,q=%h,final=%h",b_Rd,h_Rd,w_Rd,data_Rd_data,data_Rd);
  end

  wire [63:0] data_Wr;
  reg [7:0] wmask;
  reg [63:0] data_Wrr;
  always @(*) begin
    case(MemOp)
      3'b000:begin
        data_Wrr={8{data_Wr[7:0]}};
        wmask[0]=(addr[2:0]==3'o0);
        wmask[1]=(addr[2:0]==3'o1);
        wmask[2]=(addr[2:0]==3'o2);
        wmask[3]=(addr[2:0]==3'o3);
        wmask[4]=(addr[2:0]==3'o4);
        wmask[5]=(addr[2:0]==3'o5);
        wmask[6]=(addr[2:0]==3'o6);
        wmask[7]=(addr[2:0]==3'o7);
      end
      3'b001:begin
        data_Wrr={4{data_Wr[15:0]}};
        wmask[0]=(addr[2:1]==2'o0);
        wmask[1]=(addr[2:1]==2'o0);
        wmask[2]=(addr[2:1]==2'o1);
        wmask[3]=(addr[2:1]==2'o1);
        wmask[4]=(addr[2:1]==2'o2);
        wmask[5]=(addr[2:1]==2'o2);
        wmask[6]=(addr[2:1]==2'o3);
        wmask[7]=(addr[2:1]==2'o3);
      end
      3'b010:begin
        data_Wrr={2{data_Wr[31:0]}};
        wmask[3:0]={4{~addr[2]}};
        wmask[7:4]={4{addr[2]}};
      end
      default: begin
        wmask=8'hff;
        data_Wrr=data_Wr;
      end
    endcase
  end


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
    .pc(pc),.instr(instr),
    .addr(addr),.MemOp(MemOp),.MemRd(MemRd),
    .data_Rd(data_Rd),.data_Wr(data_Wr),.MemWr(MemWr),.error(error),.done(done)
  );

  import "DPI-C" function void data_write(
    input longint waddr, input longint data, input byte mask
  );

  always @(negedge clk) begin
//    if(!rst&&MemWr)$display("pc=%h,addr=%h,MemOp=%h,wmask=%h,data=%h",pc,addr,MemOp,wmask,data_Wr);
    if(!rst&&MemWr) data_write(addr,data_Wr,wmask);
  end

  assign status=cpu.module_regs.rf[10][0];
  integer i;
  always @(*) begin
    for(i=1;i<32;i=i+1) dbg_regs[i]=cpu.module_regs.rf[i];
    dbg_regs[0]=0;
//    if(MemWr&&clk)$display("Write to:addr=%h,data=%x,help=%h,real=%h,wmask=%b",addr,data_Wr,data_Wr_help,data_Wr_data,wmask);
  end
endmodule
