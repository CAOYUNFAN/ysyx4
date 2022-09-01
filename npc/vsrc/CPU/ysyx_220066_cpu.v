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
    wire [63:0] id_pc;
    //EX
    wire ex_valid,ex_wen,ex_isex,ex_is_jmp,ex_ecall,ex_mret,ex_csr,ex_done;
    wire [4:0] ex_rd;
    wire [63:0] ex_data;
    wire [11:0] ex_csr_addr;
    wire [63:0] ex_nxtpc;
    wire [63:0] ex_csr_wdata;
    wire [63:0] ex_pc;
    //M
    wire m_valid,m_wen,m_MemRd;
    wire [4:0] m_rd;
    wire [63:0] m_data;
    //Div
    wire div_ready;
    //WB
    wire wb_wen;
    wire [4:0] wb_rd;
    wire [63:0] wb_data;
    //CSR
    wire [63:0] csr_nxtpc;
    wire csr_jmp;

    wire global_block;
    assign global_block=~div_ready||~instr_valid||(MemRd&&~data_Rd_valid);

    ysyx_220066_IF module_if(
        .clk(clk),.rst(rst),.old_pc(id_pc),
        .block(global_block),
        .is_jmp(ex_is_jmp||csr_jmp),.back(id_rs_block),
        .nxtpc(csr_jmp?csr_nxtpc:ex_nxtpc),.native_pc(pc_rd)
    );
    
    ysyx_220066_Registers module_regs(
        .clk(clk),.rst(rst),.wen(wb_wen),.rd(wb_rd),.data(wb_data),
        .ex_rd(ex_rd),.ex_wen(ex_wen&&ex_valid),.ex_data(ex_data),.ex_valid(ex_isex),
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
        .raise_intr(raise_intr&&~global_block),.NO(NO),.pc(ex_pc),
        .ret(ex_mret&&ex_valid&&~global_block),
        .jmp(csr_jmp),.nxtpc(csr_nxtpc)
    );

    ysyx_220066_ID module_id(
        .clk(clk),.rst(rst),.block(global_block),
        .rs1_valid(id_rs1_valid),.rs2_valid(id_rs2_valid),.jmp((ex_is_jmp&&ex_valid)||csr_jmp),      
        .valid_in(module_if.valid),.instr(instr),.pc_in(module_if.pc),.instr_error(instr_error),
        .csr_error(module_csr.rd_err),.rs_block(id_rs_block),.pc(id_pc)
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
        .is_ex(ex_isex),.ecall(ex_ecall),.mret(ex_mret),.csr_addr(ex_csr_addr),.csr(ex_csr),.done(ex_done),.pc(ex_pc)
    );

    wire [63:0] mul_result;
    ysyx_220066_booth_walloc module_mutli(
        .clk(clk),.block(global_block),
        .src1_in(module_regs.src1),.src2_in(module_regs.src2),.ALUctr_in(module_id.ALUctr[1:0]),
        .ALUctr(module_ex.ALUctr_native[1:0]),.is_w(module_ex.ALUctr_native[4]),
        .result(mul_result)
    );

    ysyx_220066_csrwork csrwork(
        .csr_data(module_ex.csr_data),.rs1(module_ex.src1),.zimm(module_ex.rs1),.csrctl(module_ex.MemOp),.data(ex_csr_wdata)
    );

    wire div_valid,div_ready;
    wire [63:0] div_result;
    ysyx_220066_Div module_div(
        .clk(clk),.rst(rst),
        .src1_in(module_ex.src1_native),.src2_in(module_ex.src2_native),
        .is_w(module_ex.ALUctr_native[4]),.ALUctr_in(module_ex.ALUctr_native[1:0]),
        .in_valid(module_ex.valid&&module_ex.is_div&&~global_block),
        .out_valid(div_valid),.in_ready(div_ready),.result(div_result)
    );

    wire MemWr_line;
    ysyx_220066_M module_m(
        .clk(clk),.rst(rst),.valid(m_valid),.block(global_block),
        .nxtpc_in(csr_jmp?csr_nxtpc:module_ex.nxtpc),.done_in(module_ex.done),.valid_in(module_ex.valid),
        .MemRd_in(module_ex.MemRd),.ex_result(module_ex.result),.error_in(module_ex.error),
        .data_Wr_in(module_ex.src2),.RegWr_in(module_ex.RegWr),.MemWr_in(module_ex.MemWr),
        .MemOp_in(module_ex.MemOp),.rd_in(module_ex.rd),
        .is_mul(module_ex.is_mul),.mul_result(mul_result),
        .is_div(module_ex.is_div),.div_valid(div_valid),.div_result(div_result),
        .RegWr(m_wen),.rd(m_rd),
        .MemRd_native(MemRd),.MemWr_native(MemWr_line),.MemOp_native(MemOp),.addr(addr),.data_Wr(data_Wr)
    );
    assign MemWr=MemWr_line&&module_m.valid;
    assign m_MemRd=MemRd;
    assign m_data=addr;

    ysyx_220066_Wb module_wb(
        .clk(clk),.rst(rst),
        .valid_in(module_m.valid&&~global_block),.data_Rd_error(data_Rd_error),
        .wen_in(module_m.RegWr&&module_m.valid),.MemRd_in(module_m.MemRd_native),
        .done_in(module_m.done&&module_m.valid),.rd_in(module_m.rd),.data_in(module_m.data),
        .data_Rd(data_Rd),
        .error_in(module_m.error),.nxtpc_in(module_m.nxtpc),
        .rd(wb_rd),.data(wb_data),.wen(wb_wen)
    );

    always @(posedge clk) begin
        pc_nxt<=module_wb.nxtpc;
        out_valid<=module_wb.valid;
        done<=~rst&&module_wb.done;
        error<=module_wb.error||module_csr.wr_err;
//        $display("error:%b %b,data_valid=%b",error,module_wb.error,data_Rd_error);
    end

    always @(*) if(!rst) begin
        `ifdef INSTR
        if(~clk) $display("done:nxtpc=%h,out_valid=%b,error=%b",pc_nxt,out_valid,error);
        `endif
//        $display("clk=%b,pc=%h,instr=%h",clk,pc,instr);
//        if(clk) $display("iscsr?%b,Funct3=%b,csrwen=",iscsr,instr[14:12],csr_wen&&~error_temp);
    end
endmodule
