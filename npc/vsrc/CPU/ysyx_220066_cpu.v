module ysyx_220066_cpu(
    input clk,rst,
    input [31:0] instr,
    input [63:0] data_Rd,
    input instr_valid,instr_error,
    input data_Rd_valid,data_Rd_error,

    output error,MemWr,MemRd,done,
    output [2:0] MemOp,
    output [63:0] pc_rd,
    output [63:0] pc_wr,
    output out_valid,
    output [63:0] addr,
    output [63:0] data_Wr
);
    //ID
    wire id_rs1_valid,id_rs2_valid;
    //EX
    wire ex_valid,ex_wen,ex_MemRd,ex_is_jmp,ex_ecall,ex_mret,ex_done;
    wire [4:0] ex_rd;
    wire [63:0] ex_data;
    wire [11:0] ex_csr_addr;
    wire [63:0] ex_nxtpc;
    wire [63:0] ex_csr_wdata;
    wire [63:0] ex_pc;
    //M
    wire m_valid,m_wen,m_MemRd,m_ready;
    wire [4:0] m_rd;
    wire [63:0] m_data;
    //Multi
    wire mul_valid1,mul_valid2,multi_ready;
    wire [4:0] mul_rd1;
    wire [4:0] mul_rd2;
    wire [63:0] mul_data;
    //Div
    wire div_valid1,div_valid2,div_ready;
    wire [4:0] div_rd1;
    wire [4:0] div_rd2;
    wire [63:0] div_data;
    //WB
    wire wb_wen;
    wire wb_m_block,wb_multi_block,wb_div_block;
    wire [4:0] wb_rd;
    wire [63:0] wb_data;
    //CSR
    wire [63:0] csr_nxtpc;
    wire csr_jmp;

/*    assign pc_wr=m_valid?m_pc|(div_valid?div_pc:multi_pc);
    assign out_valid=m_valid||div_valid||multi_valid;
    assign error=(m_valid&&m_error)||(div_valid&&div_error)||(multi_valid&&multi_error);
    assign done=m_done&&m_valid;
    assign addr=ex_result_line;*/

    ysyx_220066_IF module_if(
        .clk(clk),.rst(rst),
        .block((~ex_is_jmp&&(~instr_valid||~id_rs1_valid||~id_rs2_valid))||id_csr||ex_csr),
        .is_jmp(ex_is_jmp||csr_jmp),.instr_valid(instr_valid),.valid(if_valid),
        .nxtpc(csr_jmp?csr_nxtpc:ex_nxtpc),.native_pc(pc_rd),
    );
    
    ysyx_220066_Registers module_regs(
        .clk(clk),.rst(rst),.wen(wb_wen),.rd(wb_rd),.data(wb_data),
        .ex_rd(ex_rd),.ex_wen(ex_wen&&ex_valid),.ex_data(ex_data),.ex_valid(~ex_MemRd),
        .m_rd(m_rd),.m_wen(m_wen&&m_valid),.m_data(m_result),.m_valid(~m_valid),
        .multi_rd1(mul_rd1),.multi_rd2(mul_rd2),.multi_valid1(mul_valid1),.multi_valid2(mul_valid2),.multi_result(mul_data),
        .div_rd1(div_rd1),.div_rd2(div_rd2),.div_valid1(div_valid1),.div_valid2(div_valid2),.div_result(div_data),
        .rs1(instr[19:15]),.rs1_valid(id_rs1_valid),
        .rs2(instr[24:20]),.rs2_valid(id_rs2_valid)
    );

    wire raise_intr;
    wire [63:0] NO;
    assign raise_intr=ex_ecall;
    assign NO=ex_ecall?64'd11:0;
    ysyx_220066_csr module_csr(
        .rst(rst),.clk(clk),
        .csr_rd_addr(instr[31:20]),
        .csr_wr_addr(ex_csr_addr),.in_data(ex_csr_data),.wen(ex_valid&&ex_csr&&~ex_ecall&&~ex_mret&&~ex_done),
        .raise_intr(raise_intr),.NO(NO),.pc(ex_pc),
        .ret(ex_mret&&ex_valid),
        .jmp(csr_jmp),.nxtpc(csr_nxtpc)
    );

    ysyx_220066_ID module_id(
        .clk(clk),.rst(rst||ex_is_jmp||csr_jmp||~id_rs1_valid||~id_rs2_valid),.block(0),        
        .valid_in(module_if.valid),.instr(instr),.in_pc(module_if.pc),.instr_error(instr_error),
        .csr_error(module_csr.rd_err),.in_pc(module_if.pc)
    );

    /*assign MemRd=id_MemRd&&id_valid;
    assign MemWr=id_MemWr&&id_valid&&~id_error;
    assign MemOp=id_MemOp;
    assign data_Wr=id_src2;*/
    ysyx_220066_EX module_ex(
        .clk(clk),.rst(rst),.block(0),
        .valid_in(module_id.valid&&module_id.is_ex&&~raise_intr),
        .valid(ex_valid),.error_in(module_id.error),
        .src1(module_regs.rs1),.src2(module_regs.rs2),.imm(module_id.imm),.in_pc(module_id.pc),
        .ALUAsrc(module_id.ALUAsrc),.ALUBsrc(module_id.ALUBsrc),.ALUctr(module_id.ALUctr),.Branch(module_id.Branch),
        .MemOp(module_id.MemOp),.MemRd_in(module_id.MemRd),.MemWr_in(module_id.MemWr),.done_in(module_id.done),
        .rd_in(module_id.rd),.RegWr_in(module_id.RegWr),.rs1_in(instr[19:15])
        
        .nxtpc(ex_nxtpc),.is_jmp(ex_is_jmp),.result(ex_data),.rd(ex_rd),.RegWr(ex_wen),
        .MemRd(ex_MemRd),.ecall(ex_ecall),.mret(ex_mret),.done(ex_done),.csr_addr(ex_csr_addr),
        .src1(ex_src1),.csr_data(ex_csr_data)
    );

    ysyx_220066_csrwork csrwork(
        .csr_data(module_ex.csr_data),.rs1(module_ex.src1),.zimm(module_ex.rs1),.csrctl(module_ex.MemOp),.data(ex_csr_wdata)
    );

    ysyx_220066_M module_m(
        .clk(clk),.rst(rst),.ready(m_ready),.valid(ex_valid),.pc_in(ex_pc),.done_in(ex_done),
        .valid_in(ex_valid&&(~ex_MemRd||data_Rd_valid)),.block(ex_MemRd&&~data_Rd_valid),
        .MemRd(ex_MemRd),.ex_result(ex_result),.error_in(id_error||(ex_MemRd&&data_Rd_error)),
        .data_Rd(data_Rd), .m_out(m_result),.RegWr(m_RegWr),.error(m_error),
        .pc(m_pc),.done(m_done)
    );TODO!

    ysyx_220066_Multi module_mutli(
        .clk(clk),.rst(rst),.block(wb_multi_block),
        .valid_in(module_id.valid&&module_id.is_Multi),.error_in(module_id.error),.pc_in(module_id.pc),
        .ready(multi_ready),
        .valid(multi_valid2),.valid_part(multi_valid1),.rd_part(multi_rd1),.rd(multi_rd2),
        .rs1(module_id.rs1),.rs2(module_id.rs2),.ALUctr(module_id.ALUctr[1:0]),.is_w(module_id.ALUctr[4]),.rd_in(id_rd),
        .result(multi_result),.error(multi_error)
    );

    ysyx_220066_Div module_div(
        .clk(clk),.rst(rst),.block(wb_div_block),
        .valid_in(module_id.valid&&id_is_Div),error_in(module_id.error),.pc_in(module_id.pc),
        .ready(div_ready),
        .valid(div_valid2),.valid_part(div_valid1),.rd_part(div_rd1),.rd(div_rd2),
        .rs1(module_id.rs1),.rs2(module_id.rs2),.ALUctr(module_id.ALUctr[1:0]),is_w(Amodule_id.LUctr[4]),.rd_in(id_rd),
        .result(div_result),.error(div_error)
    );

    TODO!

    always @(*) if(!rst) begin
//        $display("clk=%b,pc=%h,instr=%h",clk,pc,instr);
//        if(clk) $display("iscsr?%b,Funct3=%b,csrwen=",iscsr,instr[14:12],csr_wen&&~error_temp);
    end
endmodule
