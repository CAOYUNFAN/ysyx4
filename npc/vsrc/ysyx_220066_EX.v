module ysyx_220066_Ex(
    input [63:0] src1,
    input [63:0] src2,
    input [63:0] imm,
    input [63:0] in_pc,
    input ALUAsrc,
    input [1:0] ALUBsrc,
    input [4:0] ALUctr,
    input [2:0] Branch,

    output [63:0] result,
    output [63:0] nxtpc
)
    wire zero;
    ysyx_220066_ALU ysyx_220066_alu(
        .data_input(ALUAsrc?in_pc}:src1),
        .datab_input(ALUBSrc[1]?imm:(ALUBSrc[0]?64'h4:BusB)),
        .aluctr(ALUctr),.zero(zero),.result(result)
        );

    ysyx_220066_nxtPC nxtPC(
        .nxtpc(nxtpc),.in_pc(in_pc),.BusA(src1),.Imm(imm),.Zero(zero),
        .Result_0(result[0]),.Branch(Branch)
        );

endmodule

module ysyx_220066_jmp_control(
    input Zero,Result_0,
    input [2:0] Branch,
    output NxtASrc,
    output reg NxtBSrc
    );
    assign NxtASrc=(Branch==3'b010);
    always @(*)
    case (Branch)
        3'b000:NxtBSrc=0;
        3'b001:NxtBSrc=1;
        3'b010:NxtBSrc=1;
        3'b100:NxtBSrc=Zero;
        3'b101:NxtBSrc=!Zero;
        3'b110:NxtBSrc=Result_0;
        3'b111:NxtBSrc=Zero|(!Result_0);
    endcase
endmodule

module ysyx_220066_nxtPC(
    output [63:0] nxtpc,
    input [63:0] in_pc,
    input [63:0] BusA,
    input [63:0] Imm,
    input Zero,
    input Result_0,
    input [2:0] Branch
    );
    wire NxtASrc,NxtBSrc;
    yxys_220066_jmp_control jmp(Zero,Result_0,Branch,NxtASrc,NxtBSrc);
    assign nxtpc=(NxtASrc?BusA:in_pc)+(NxtBSrc?Imm:63'h4);
endmodule
