module yxys_220066_jmp_control(
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
        3'b011:NxtBSrc=1;
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
    assign nxtpc=(NxtASrc?BusA:in_pc)+(NxtBSrc?Imm:64'h4);
    always @(*) begin
        $display("nxtPC:B=%b,Result_0=%b",NxtBSrc,Result_0);
    end
endmodule
