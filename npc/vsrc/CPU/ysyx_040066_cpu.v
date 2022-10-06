module ysyx_040066_cpu(
    input clk,rst,
    input [31:0] instr_rd,
    input [63:0] data_Rd,
    input instr_valid,instr_error,
    input data_valid,data_error,

    output reg error,done,
    output MemWr,MemRd,fence_i,instr_read,
    output [63:0] pc_rd,
    output reg [63:0] pc_nxt,
    output reg out_valid,
    output [63:0] addr,
    output [2:0] wr_len,
    output [7:0] wr_mask,
    output [63:0] data_Wr
);
    //ID
    wire id_rs1_valid,id_rs2_valid;
    //EX
    wire ex_valid,ex_wen,ex_isex,ex_is_jmp,ex_ecall,ex_mret,ex_csr,ex_done;
    wire [4:0] ex_rd;
    wire [63:0] ex_data;
    wire [11:0] ex_csr_addr;
    wire [63:0] ex_nxtpc;
    wire [63:0] ex_csr_wdata;
    wire [63:0] ex_pc;
    reg [31:0] ex_instr; always@(posedge clk) ex_instr<=instr_rd;
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
    wire [63:0] wb_pc,wb_addr;
    //CSR
    wire [63:0] csr_nxtpc;
    wire csr_jmp;

    wire [31:15] instr;

    wire div_block,instr_block,mem_block,id_block;
    assign div_block=~div_ready;
    assign instr_block=~instr_valid;
    assign mem_block=(MemRd||MemWr)&&~data_valid;
    wire m_block,global_block;
    assign m_block=div_block||mem_block;
    assign global_block=instr_block||m_block;

    ysyx_040066_IF module_if(
        .clk(clk),.rst(rst),
        .block(global_block),.id_block(id_block),
        .is_jmp(ex_is_jmp||csr_jmp),
        .nxtpc(csr_jmp?csr_nxtpc:ex_nxtpc),.native_pc(pc_rd)
    );
    assign instr_read=~(global_block||id_block);
    ysyx_040066_Registers module_regs(
        .clk(clk),.wen(wb_wen),.rd(wb_rd),.data(wb_data),
        .ex_rd(ex_rd),.ex_wen(ex_wen&&ex_valid),.ex_data(ex_data),.ex_valid(ex_isex),
        .m_rd(m_rd),.m_wen(m_wen&&m_valid),.m_data(m_data),.m_valid(~m_MemRd),
        .rs1(instr[19:15]),.rs1_valid(id_rs1_valid),
        .rs2(instr[24:20]),.rs2_valid(id_rs2_valid)
    );

    wire raise_intr,ex_valid_native,intr_time,clear_mip;
    wire intr_ecall,intr_t,intr_ins_ac,intr_ins_dec,intr_rd,intr_wr;
    wire [63:0] NO,mstatus,mie,tval;
    assign intr_ecall=ex_ecall&&ex_valid_native;
    assign intr_t=intr_time&&mstatus[3]&&mie[7];
    assign raise_intr=intr_ecall||intr_t||intr_ins_ac||intr_ins_dec||intr_rd||intr_wr;
    assign NO[62:0]=intr_rd?63'd5:intr_wr?63'd7:
                    intr_ecall?63'd11:
                    intr_ins_ac?63'd1:intr_ins_dec?63'd2:
                    intr_t?63'd7:63'd0;
    assign NO[63]=~intr_rd&&~intr_wr&&~intr_ecall&&~intr_ins_ac&&~intr_ins_dec&&intr_t;
    assign tval=(intr_rd||intr_wr)?wb_addr:intr_ins_ac?ex_pc:intr_ins_dec?{32'h0,ex_instr}:64'b0;
    ysyx_040066_csr module_csr(
        .rst(rst),.clk(clk),.clear_mip(clear_mip),
        .csr_rd_addr(instr[31:20]),
        .csr_wr_addr(ex_csr_addr),.in_data(ex_csr_wdata),.wen(ex_valid&&ex_csr&&~ex_ecall&&~ex_mret&&~ex_done),
        .raise_intr(raise_intr&&~global_block),.NO(NO),.pc((intr_rd||intr_wr)?wb_pc:ex_pc),.tval(tval),
        .ret(ex_mret&&ex_valid&&~global_block),.mstatus(mstatus),.mie(mie),
        .jmp(csr_jmp),.nxtpc(csr_nxtpc)
    );

    ysyx_040066_ID module_id(
        .clk(clk),.rst(rst),.block(global_block||id_block),
        .rs1_valid(id_rs1_valid),.rs2_valid(id_rs2_valid),.jmp((ex_is_jmp&&ex_valid)||csr_jmp),      
        .valid_in(module_if.valid),.instr_read(instr_rd),.pc_in(module_if.pc),.instr_error_rd(instr_error),
        .csr_error(module_csr.rd_err),.rs_block(id_block)
    );
    assign instr=module_id.instr[31:15];

    ysyx_040066_EX module_ex(
        .clk(clk),.rst(rst),.block(global_block),
        .valid_in(module_id.valid),.raise_intr(intr_t||intr_rd||intr_wr),
        .valid(ex_valid),.error_in(module_id.error),.rd_in(module_id.rd),
        .src1_in(module_regs.src1),.src2_in(module_regs.src2),.imm_in(module_id.imm),.pc_in(module_id.pc),
        .csr_data_in(module_csr.csr_data),.csr_addr_in(module_id.csr_addr),.csr_in(module_id.csr),
        .ecall_in(module_id.ecall),.mret_in(module_id.mret),
        .ALUAsrc_in(module_id.ALUASrc),.ALUBsrc_in(module_id.ALUBSrc),.ALUctr_in(module_id.ALUctr),.Branch_in(module_id.Branch),
        .MemOp_in(module_id.MemOp),.MemRd_in(module_id.MemRd),.MemWr_in(module_id.MemWr),.done_in(module_id.done),
        .RegWr_in(module_id.RegWr),.rs1_in(instr[19:15]),.fence_i_in(module_id.fence_i),
        
        .nxtpc(ex_nxtpc),.is_jmp(ex_is_jmp),.result(ex_data),.rd(ex_rd),.RegWr(ex_wen),.valid_native(ex_valid_native),
        .is_ex(ex_isex),.ecall(ex_ecall),.mret(ex_mret),.csr_addr(ex_csr_addr),.csr(ex_csr),.done(ex_done),.pc(ex_pc)
    );
    assign intr_ins_ac=module_ex.error[0]&&module_ex.valid;
    assign intr_ins_dec=module_ex.error[1]&&module_ex.valid;


    wire [63:0] mul_result;

    `ifdef EMU_MULTI
    multi_dummy module_mutli(
        .clk(clk),.block(global_block),
        .src1_in(module_regs.src1),.src2_in(module_regs.src2),.ALUctr_in(module_id.ALUctr[1:0]),
        .ALUctr(module_ex.ALUctr_native[1:0]),.is_w(module_ex.ALUctr_native[4]),
        .result(mul_result)
    );
    `else
    ysyx_040066_booth_walloc module_mutli(
        .clk(clk),.block(global_block),
        .src1_in(module_regs.src1),.src2_in(module_regs.src2),.ALUctr_in(module_id.ALUctr[1:0]),
        .ALUctr(module_ex.ALUctr_native[1:0]),.is_w(module_ex.ALUctr_native[4]),
        .result(mul_result)
    );
    `endif

    ysyx_040066_csrwork csrwork(
        .csr_data(module_ex.csr_data),.rs1(module_ex.src1),.zimm(module_ex.rs1),.csrctl(module_ex.MemOp),.data(ex_csr_wdata)
    );

    wire div_valid,div_ready;
    wire [63:0] div_result;
    ysyx_040066_Div module_div(
        .clk(clk),.rst(rst||intr_rd||intr_wr),
        .src1_in(module_ex.src1_native),.src2_in(module_ex.src2_native),
        .is_w(module_ex.ALUctr_native[4]),.ALUctr_in(module_ex.ALUctr_native[1:0]),
        .in_valid(module_ex.valid&&module_ex.is_div&&~global_block),
        .out_valid(div_valid),.in_ready(div_ready),.result(div_result)
    );

    wire MemWr_line,MemRd_line;
    ysyx_040066_M module_m(
        .clk(clk),.rst(rst),.valid(m_valid),.block(m_block),
        .nxtpc_in(csr_jmp?csr_nxtpc:module_ex.nxtpc),.done_in(module_ex.done),.valid_in(module_ex.valid&&~instr_block),
        .MemRd_in(module_ex.MemRd),.ex_result(module_ex.result),.error_in(module_ex.error[0]||module_ex.error[1]),
        .data_Wr_in(module_ex.data_Wr),.wr_mask_in(module_ex.wmask),.RegWr_in(module_ex.RegWr),.MemWr_in(module_ex.MemWr),
        .MemOp_in(module_ex.MemOp),.rd_in(module_ex.rd),.fence_i_in(module_ex.fence_i),
        .is_mul_in(module_ex.is_mul),.mul_result(mul_result),
        .is_div_in(module_ex.is_div),.div_valid(div_valid),.div_result(div_result),
        .RegWr(m_wen),.rd(m_rd),.wr_mask(wr_mask),.wr_len(wr_len),
        .MemRd_native(MemRd_line),.MemWr_native(MemWr_line),.addr(addr),.data_Wr(data_Wr),.fence_i(fence_i)
    );
    assign m_MemRd=MemRd_line;
    assign m_data=module_m.data;

    wire [63:0] client_data;
    wire rd_time,t_err;
    ysyx_040066_clinet module_client(
        .clk(clk),.rst(rst),.addr(addr),.data(data_Wr),
        .MemRd(MemRd_line&&module_m.valid),.MemWr(MemWr_line&&module_m.valid),
        .MemRd_real(MemRd),.MemWr_real(MemWr),.intr(intr_time),
        .data_rd(client_data),.MemRd_time(rd_time),.error(t_err)
    );
    assign clear_mip=MemWr_line&&module_m.valid&&~MemWr;

    ysyx_040066_Wb module_wb(
        .clk(clk),.rst(rst),.block((intr_rd||intr_wr)&&global_block),
        .valid_in(module_m.valid&&~m_block&&~intr_rd&&~intr_wr),.data_error(rd_time?t_err:data_error),
        .wen_in(module_m.RegWr&&module_m.valid),.MemRd_in(module_m.MemRd_native),.MemWr_in(module_m.MemWr_native),
        .done_in(module_m.done&&module_m.valid),.rd_in(module_m.rd),.data_in(module_m.data),
        .data_Rd(rd_time?client_data:data_Rd),.MemOp_in(module_m.MemOp_native),.addr_lowbit_in(module_m.addr[2:0]),
        .error_in(module_m.error),.nxtpc_in(module_m.nxtpc),
        .rd(wb_rd),.data(wb_data),.wen(wb_wen)
    );
    assign intr_rd=module_wb.data_error&&module_wb.valid&&module_wb.MemRd_native;
    assign intr_wr=module_wb.data_error&&module_wb.valid&&module_wb.MemWr_native;
    assign wb_pc=module_wb.nxtpc-64'h4;
    assign wb_addr=module_wb.data_native;

    always @(posedge clk) begin
        pc_nxt<=module_wb.nxtpc;
        out_valid<=module_wb.valid;
        done<=~rst&&module_wb.done;
        error<=module_wb.error||module_csr.wr_err;
//        $display("error:%b %b,data_valid=%b",error,module_wb.error,data_Rd_error);
    end

    always @(*) if(!rst) begin
        `ifdef INSTR
        if(~clk) $display("done:nxtpc=%h,out_valid=%b,error=%b,global_block=%b",pc_nxt,out_valid,error,global_block);
        `endif
//        $display("clk=%b,pc=%h,instr=%h",clk,pc,instr);
//        if(clk) $display("iscsr?%b,Funct3=%b,csrwen=",iscsr,instr[14:12],csr_wen&&~error_temp);
    end
endmodule
