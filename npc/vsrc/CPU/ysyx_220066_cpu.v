module ysyx_220066_cpu(
    input clk,rst,
    input [31:0] instr,
    input [63:0] data_Rd,
    input instr_valid,instr_error,
    input data_Rd_valid,data_Rd_error,

    output reg error,done,
    output MemWr,MemRd,
    output [2:0] MemOp,
    output [63:0] pc_rd,
    output reg [63:0] pc_nxt,
    output reg out_valid,
    output [63:0] addr,
    output [63:0] data_Wr
);
    //ID
    wire id_rs1_valid,id_rs2_valid,id_rs_block;
    //EX
    wire ex_valid,ex_wen,ex_MemRd,ex_is_jmp,ex_ecall,ex_mret,ex_csr,ex_done;
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
/*    //Multi
    wire mul_valid1,mul_valid2,multi_ready;
    wire [4:0] mul_rd1;
    wire [4:0] mul_rd2;
    wire [63:0] mul_data;
    //Div
    wire div_valid1,div_valid2,div_ready;
    wire [4:0] div_rd1;
    wire [4:0] div_rd2;
    wire [63:0] div_data;*/
    //WB
    wire wb_wen,wb_m_block;
 //   wire ,wb_multi_block,wb_div_block;
    wire [4:0] wb_rd;
    wire [63:0] wb_data;
    //CSR
    wire [63:0] csr_nxtpc;
    wire csr_jmp;

    ysyx_220066_IF module_if(
        .clk(clk),.rst(rst),
        .block(~ex_is_jmp&&~csr_jmp&&(~instr_valid||id_rs_block)),
        .is_jmp(ex_is_jmp||csr_jmp),
        .nxtpc(csr_jmp?csr_nxtpc:ex_nxtpc),.native_pc(pc_rd)
    );
    
    ysyx_220066_Registers module_regs(
        .clk(clk),.rst(rst),.wen(wb_wen),.rd(wb_rd),.data(wb_data),
        .ex_rd(ex_rd),.ex_wen(ex_wen&&ex_valid),.ex_data(ex_data),.ex_valid(~ex_MemRd),
        .m_rd(m_rd),.m_wen(m_wen&&m_valid),.m_data(m_data),.m_valid(~m_MemRd),
        .rs1(instr[19:15]),.rs1_valid(id_rs1_valid),
        .rs2(instr[24:20]),.rs2_valid(id_rs2_valid)
    );

    wire raise_intr,ex_valid_native;
    wire [63:0] NO;
    assign raise_intr=ex_ecall&&ex_valid_native;
    assign NO=ex_ecall?64'd11:0;
    ysyx_220066_csr module_csr(
        .rst(rst),.clk(clk),
        .csr_rd_addr(instr[31:20]),
        .csr_wr_addr(ex_csr_addr),.in_data(ex_csr_wdata),.wen(ex_valid&&ex_csr&&~ex_ecall&&~ex_mret&&~ex_done),
        .raise_intr(raise_intr),.NO(NO),.pc(ex_pc),
        .ret(ex_mret&&ex_valid),
        .jmp(csr_jmp),.nxtpc(csr_nxtpc)
    );

    ysyx_220066_ID module_id(
        .clk(clk),.rst(rst),.block(0),
        .rs1_valid(id_rs1_valid),.rs2_valid(id_rs2_valid),.jmp((ex_is_jmp&&ex_valid)||csr_jmp),      
        .valid_in(module_if.valid),.instr(instr),.pc_in(module_if.pc),.instr_error(instr_error),
        .csr_error(module_csr.rd_err),.rs_block(id_rs_block)
    );

    ysyx_220066_EX module_ex(
        .clk(clk),.rst(rst),.block(0),
        .valid_in(module_id.valid),.raise_intr(raise_intr),
        .valid(ex_valid),.error_in(module_id.error),.rd_in(module_id.rd),
        .src1_in(module_regs.src1),.src2_in(module_regs.src2),.imm_in(module_id.imm),.pc_in(module_id.pc),
        .csr_data_in(module_csr.csr_data),.csr_addr_in(module_id.csr_addr),.csr_in(module_id.csr),
        .ecall_in(module_id.ecall),.mret_in(module_id.mret),
        .ALUAsrc_in(module_id.ALUASrc),.ALUBsrc_in(module_id.ALUBSrc),.ALUctr_in(module_id.ALUctr),.Branch_in(module_id.Branch),
        .MemOp_in(module_id.MemOp),.MemRd_in(module_id.MemRd),.MemWr_in(module_id.MemWr),.done_in(module_id.done),
        .RegWr_in(module_id.RegWr),.rs1_in(instr[19:15]),
        
        .nxtpc(ex_nxtpc),.is_jmp(ex_is_jmp),.result(ex_data),.rd(ex_rd),.RegWr(ex_wen),.valid_native(ex_valid_native),
        .MemRd(ex_MemRd),.ecall(ex_ecall),.mret(ex_mret),.csr_addr(ex_csr_addr),.csr(ex_csr),.done(ex_done)
    );

    ysyx_220066_csrwork csrwork(
        .csr_data(module_ex.csr_data),.rs1(module_ex.src1),.zimm(module_ex.rs1),.csrctl(module_ex.MemOp),.data(ex_csr_wdata)
    );

    wire MemWr_line;
    ysyx_220066_M module_m(
        .clk(clk),.rst(rst),.ready(m_ready),.valid(m_valid),.block(wb_m_block),
        .nxtpc_in(module_ex.nxtpc),.done_in(module_ex.done),.valid_in(module_ex.valid),
        .MemRd_in(module_ex.MemRd),.ex_result(module_ex.result),.error_in(module_ex.error),
        .data_Wr_in(module_ex.src2),.RegWr_in(module_ex.RegWr),.MemWr_in(module_ex.MemWr),
        .MemOp_in(module_ex.MemOp),.rd_in(module_ex.rd),
        .RegWr(m_wen),.rd(m_rd),
        .MemRd_native(MemRd),.MemWr_native(MemWr_line),.MemOp_native(MemOp),.addr(addr),.data_Wr(data_Wr)
    );
    assign MemWr=MemWr_line&&module_m.valid;
    assign m_MemRd=MemRd;
    assign m_data=addr;

//    ysyx_220066_Multi module_mutli(
//        .clk(clk),.rst(rst),.block(wb_multi_block),
//        .valid_in(module_id.valid&&module_id.is_Multi),.error_in(module_id.error),.nxtpc_in(module_id.pc+4),
//        .ready(multi_ready),
//        .valid(mul_valid2),.valid_part(mul_valid1),.rd_part(mul_rd1),.rd(mul_rd2),
//        .src1_in(module_regs.src1),.src2_in(module_regs.src2),.ALUctr_in(module_id.ALUctr[1:0]),.is_w_in(module_id.ALUctr[4]),.rd_in(module_id.rd),
//        .result(mul_data)
//    );

//    ysyx_220066_Div module_div(
//        .clk(clk),.rst(rst),.block(wb_div_block),
//        .valid_in(module_id.valid&&module_id.is_Div),.error_in(module_id.error),.nxtpc_in(module_id.pc+4),
//        .ready(div_ready),
//        .valid(div_valid2),.valid_part(div_valid1),.rd_part(div_rd1),.rd(div_rd2),
//        .src1_in(module_regs.src1),.src2_in(module_regs.src2),.ALUctr_in(module_id.ALUctr[1:0]),.is_w_in(module_id.ALUctr[4]),.rd_in(module_id.rd),
//        .result(div_data)
//    );

    ysyx_220066_Wb module_wb(
        .clk(clk),.rst(rst),
        .M_valid_in(module_m.valid),.data_Rd_error(data_Rd_error),
        .M_wen_in(module_m.RegWr&&module_m.valid),.M_MemRd_in(module_m.MemRd_native),
        .M_done_in(module_m.done&&module_m.valid),.M_rd_in(module_m.rd),.M_data_in(module_m.addr),
        .data_Rd(data_Rd),.data_Rd_valid(data_Rd_valid),
        .M_error_in(module_m.error),.M_nxtpc_in(module_m.nxtpc),
        /*.Multi_wen_in(module_mutli.valid),.Multi_data_in(module_mutli.result),.Multi_rd_in(module_mutli.rd),
        .Multi_error_in(module_mutli.error),.Multi_nxtpc_in(module_mutli.nxtpc),
        .Div_wen_in(module_div.valid),.Div_data_in(module_div.result),.Div_rd_in(module_div.rd),
        .Div_error_in(module_div.valid),.Div_nxtpc_in(module_div.nxtpc),*/
        .rd(wb_rd),.data(wb_data),.wen(wb_wen),
        .m_block(wb_m_block)//,.multi_block(wb_multi_block),.div_block(wb_div_block)
    );

    always @(posedge clk) begin
        pc_nxt<=module_wb.nxtpc;
        out_valid<=module_wb.valid;
        done<=~rst&&module_wb.done;
        error<=module_wb.error||module_csr.wr_err;
        $display("error:%b %b %b",error,module_csr.wr_err,module_wb.error);
    end

    always @(*) if(!rst) begin
        if(~clk) $display("done:nxtpc=%h,out_valid=%b,error=%b",pc_nxt,out_valid,error);
//        $display("clk=%b,pc=%h,instr=%h",clk,pc,instr);
//        if(clk) $display("iscsr?%b,Funct3=%b,csrwen=",iscsr,instr[14:12],csr_wen&&~error_temp);
    end
endmodule
