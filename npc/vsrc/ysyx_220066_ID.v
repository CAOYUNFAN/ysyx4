module ysyx_220066_ID (
    input [31:0] instr,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [63:0] imm
);
    assign rs1=instr[19:15];
    assign rd=instr[11:7];
    assign imm[63:12]={52{instr[31]}};
    assign imm[11:0]=instr[31:20];
endmodule
