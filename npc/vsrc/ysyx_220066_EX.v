module ysyx_220066_EX(
    input [63:0] src1,
    input [63:0] src2,
    input [63:0] imm,
    input [63:0] in_pc,
    input ALUAsrc,
    input [1:0] ALUBsrc,
    input [5:0] ALUctr,
    input [2:0] Branch,

    output [63:0] result,
    output [63:0] nxtpc
);
    wire zero;
    wire [63:0] result_alu;
    wire [63:0] result_mul;
    assign result=ALUctr[5]?result_mul:result_alu;
    ysyx_220066_ALU alu(
        .data_input(ALUAsrc?in_pc:src1),
        .datab_input(ALUBsrc[1]?imm:(ALUBsrc[0]?64'h4:src2)),
        .aluctr(ALUctr[4:0]),.zero(zero),.result(result_alu)
        );
    ysyx_220066_Multi multi(
        .src1(src1),.src2(src2),.ALUctr(ALUctr[2:0]),.result(result_mul)
    );
    ysyx_220066_nxtPC nxtPC(
        .nxtpc(nxtpc),.in_pc(in_pc),.BusA(src1),.Imm(imm),.Zero(zero),
        .Result_0(result[0]),.Branch(Branch)
        );
    always @(*) begin
        $display("EX:result=%h,ALUctr=%h",result,ALUctr);
    end
endmodule
