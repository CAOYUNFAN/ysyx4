module ysyx_220066_EX(
    input clk,rst,block,valid_in,error_in,
    output valid,

    input [63:0] src1_in,
    input [63:0] src2_in,
    input [31:0] imm_in,
    input [63:0] csr_data_in,
    input [63:0] pc_in,
    input [11:0] csr_addr_in,
    input ALUAsrc_in,done_in,csr_in,
    input ecall_in,mret_in,
    input [1:0] ALUBsrc_in,
    input [5:0] ALUctr_in,
    input [4:0] rd_in,
    input [4:0] rs1_in,
    input [2:0] Branch_in,
    input [2:0] MemOp_in,
    input MemRd_in,MemWr_in,RegWr_in,
    input raise_intr,

    output [63:0] nxtpc,
    output is_jmp,
    output [4:0] rd,
    output [63:0] result,
    output [11:0] csr_addr,
    output MemRd,RegWr,ecall,mret,csr,done,
    output reg valid_native
);
    wire [2:0] MemOp;
    wire [4:0] rs1;
    wire [63:0] src1;
    wire [63:0] src2;
    wire [63:0] csr_data;
    wire MemWr,error;
    wire [63:0] pc;

    reg error_native,csr_native,ecall_native,mret_native;
    reg [63:0] src1_native;
    reg [63:0] src2_native;
    reg [31:0] imm_native;
    reg [63:0] csr_data_native;
    reg [63:0] pc_native;
    reg ALUAsrc_native,done_native;
    reg [1:0] ALUBsrc_native;
    reg [5:0] ALUctr_native;
    reg [2:0] Branch_native;
    reg [2:0] MemOp_native;
    reg MemRd_native,MemWr_native,RegWr_native;
    reg [11:0] csr_addr_native;
    reg [4:0] rd_native;
    reg [4:0] rs1_native;

    always @(posedge clk) valid_native<=~rst&&(block?valid_native:valid_in);
    
    always @(posedge clk) if(~block) begin
        error_native<=error_in;
        src1_native<=src1_in;
        src2_native<=src2_in;
        imm_native<=imm_in;
        csr_data_native<=csr_data_in;
        pc_native<=pc_in;
        ALUAsrc_native<=ALUAsrc_in;
        ALUBsrc_native<=ALUBsrc_in;
        done_native<=done_in;
        ALUctr_native<=ALUctr_in;
        rs1_native<=rs1_in;
        Branch_native<=Branch_in;
        MemOp_native<=MemOp_in;
        rd_native<=rd_in;
        MemRd_native<=MemRd_in;
        MemWr_native<=MemWr_in;
        RegWr_native<=RegWr_in;
        csr_addr_native<=csr_addr_in;
        csr_native<=csr_in;ecall_native<=ecall_in;mret_native<=mret_in;
        //$display("EX:src2=%h,src2_in=%h",src2_native,src2_in);
    end

    assign valid=valid_native&&~raise_intr;
    assign done=done_native;
    assign MemOp=MemOp_native;
    assign MemRd=MemRd_native;
    assign MemWr=MemWr_native;
    assign src1=src1_native;
    assign src2=src2_native;
    assign csr_addr=csr_addr_native;
    assign csr_data=csr_data_native;
    assign ecall=ecall_native;
    assign mret=mret_native;
    assign rd=rd_native;
    assign RegWr=RegWr_native;
    assign rs1=rs1_native;
    assign csr=csr_native;
    assign pc=pc_native;

    wire [63:0] imm_use;
    assign imm_use={{32{imm_native[31]}},imm_native};

    reg [63:0] datab;
    always @(*) case(ALUBsrc_native)
        2'b00:datab=src2_native;
        2'b01:datab=64'h4;
        2'b10:datab=imm_use;
        2'b11:datab=csr_data_native;
    endcase
    wire zero;
    wire [63:0] result_line;
    wire [63:0] mul_result;

    ysyx_220066_ALU alu(
        .data_input(ALUAsrc_native?pc_native:src1_native),.datab_input(datab),
        .aluctr(ALUctr_native[4:0]),.zero(zero),.result(result_line)
    );

    wire error_multi;
    ysyx_220066_Multi_dummy multi_dummy(
        .src1(src1_native),.src2(src2_native),.is_w(ALUctr_native[4]),.ALUctr(ALUctr_native[2:0]),
        .result(mul_result),.error(error_multi)
    );

    wire is_jmp_line;
    ysyx_220066_nxtPC nxtPC(
        .nxtpc(nxtpc),.is_jmp(is_jmp_line),.in_pc(pc_native),.BusA(src1_native),.Imm(imm_use),.Zero(zero),
        .Result_0(result_line[0]),.Branch(Branch_native)
    );

    assign error=error_native||(ALUctr_native[5]&&error_multi);
    assign is_jmp=(is_jmp_line||csr_native)&&valid_native;
    assign result=ALUctr_native[5]?mul_result:result_line;

    always @(*) begin
        //if(~rst&&~clk) $display("EX:nxtpc=%h,valid=%b,csr_addr=%h,result=%h,is_jmp=%b,is_csr=%b,MemWr=%b,error=%b,done=%b",nxtpc,valid,csr_addr,result,is_jmp,csr_native,MemWr_native,error,done);
    end
endmodule
