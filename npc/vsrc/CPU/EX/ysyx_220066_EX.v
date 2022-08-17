module ysyx_220066_EX(
    input clk,rst,block,in_valid,
    output valid,ready,

    input valid_in,
    input [63:0] src1,
    input [63:0] src2,
    input [31:0] imm,
    input [63:0] in_pc,
    input ALUAsrc,
    input [1:0] ALUBsrc,
    input [4:0] ALUctr,
    input [2:0] Branch,
    input [2:0] MemOp,
    input MemRd_in,MemWr_in,

    output [63:0] nxtpc,
    output reg [63:0] result,
    output reg [63:0] pc,
    output reg MemRd,MemWr,
    output reg [2:0] MemOp
);
    wire zero;
    wire [63:0] result_alu;
    wire [63:0] result_mul;
    wire [63:0] imm_real;
    assign imm_real={{32{imm[31]}},imm};
    assign ready=~(valid&&block);

    ysyx_220066_ALU alu(
        .data_input(ALUAsrc?in_pc:src1),
        .datab_input(ALUBsrc[1]?imm_real:(ALUBsrc[0]?64'h4:src2)),
        .aluctr(ALUctr),.zero(zero),.result(result_alu)
    );

//    ysyx_220066_Multi multi(
//        .src1(src1),.src2(src2),.ALUctr(ALUctr[2:0]),.is_w(ALUctr[4]),.result(result_mul)
//    );

    ysyx_220066_nxtPC nxtPC(
        .nxtpc(nxtpc),.in_pc(in_pc),.BusA(src1),.Imm(imm_real),.Zero(zero),
        .Result_0(result[0]),.Branch(Branch)
    );

    always @(posedge clk) begin
        if(rst) valid<=0;
        else if(~(valid&&block)) valid<=valid_in;
    end

    always @(posedge clk) if(~(valid&&block)) begin
        result<=result_alu;
        pc<=in_pc;
        MemRd<=MemRd_in;
        MemWr<=MemWr_in;
        MemOp<=MemOp_in;
    end

    always @(*) begin
//        $display("EX:src1=%h,ALUBsrc=%h,src2=%h,imm=%h,result=%h,ALUctr=%b",src1,ALUBsrc,src2,imm,result,ALUctr);
    end
endmodule
