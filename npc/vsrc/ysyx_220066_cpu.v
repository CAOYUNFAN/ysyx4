module ysyx_220066_cpu(
    input clk,rst,
    input [31:0] instr,
    input [63:0] data_Rd,

    output error,MemWr,MemRd,done,
    output [2:0] MemOp,
    output [63:0] pc,
    output [63:0] addr,
    output [63:0] data_Wr
);
    wire [63:0] nxtpc;
    ysyx_220066_IF module_if(
        .clk(~clk),.rst(rst),
        .nxtpc(nxtpc),.pc(pc)
    );

    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [63:0] imm;
    wire [63:0] result;
    wire [1:0] ALUBsrc;
    wire ALUAsrc,MemToReg,RegWr;
    wire [5:0] ALUctr;
    wire [2:0] Branch;
    wire error_temp;
    assign error=error_temp&!rst;

    ysyx_220066_ID module_id(
        .instr(instr),
        .rs1(rs1),.rs2(rs2),.rd(rd),.imm(imm),
        .ALUASrc(ALUAsrc),.ALUBSrc(ALUBsrc),.ALUctr(ALUctr),.RegWr(RegWr),.MemRd(MemRd),
        .Branch(Branch),.MemWr(MemWr),.MemOp(MemOp),.MemToReg(MemToReg),.error(error_temp),.done(done)
    );

    wire [63:0] result;
    ysyx_220066_Regs module_regs(
        .clk(~clk),.wdata(result),.waddr(rd),.wen(RegWr)
    );

    wire [63:0] src1; 
    assign src1=(rs1==5'h0 ? 64'h0:module_regs.rf[rs1]);
    wire [63:0] src2; 
    assign src2=(rs2==5'h0 ? 64'h0:module_regs.rf[rs2]);
    wire [63:0] alu_result;
    ysyx_220066_EX module_ex(
        .src1(src1),.src2(src2),.imm(imm),.in_pc(pc),
        .ALUAsrc(ALUAsrc),.ALUBsrc(ALUBsrc),.ALUctr(ALUctr),.Branch(Branch),
        .result(alu_result),.nxtpc(nxtpc)
    );
    assign data_Wr=src2;
    ysyx_220066_M module_m(
        .MemToReg(MemToReg),.ALUout(alu_result),
        .data_read(data_Rd), .m_out(result)
    );
    assign addr=alu_result;

    always @(*) if(!rst) begin
        $display("clk=%b,pc=%h,instr=%h",clk,pc,instr);
        //$display("rd=%h,data=%x,wen=%b",rd,result,RegWr);
    end
endmodule
