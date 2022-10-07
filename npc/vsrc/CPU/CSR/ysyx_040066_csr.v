module ysyx_040066_csr (
    input rst,clk,
    input [11:0] csr_rd_addr,
    input [11:0] csr_wr_addr,
    input wen,
    input [63:0] in_data,//for csr instruction
    
    input raise_intr,
    input [63:0] NO,
    input [63:0] tval,
    input [63:0] pc,

    input ret,clear_mip,

    output jmp,
    output [63:0] nxtpc,

    output reg [63:0] mie,
    output reg [63:0] mstatus
);
    wire [63:0] csr_data;
    reg [63:0] csr_data_native;
    reg rd_err;
    wire wr_err;

    reg [63:0] mepc;
    reg [63:0] mcause;
    reg [63:0] mtvec;
    reg [63:0] mip;
    reg [63:0] mtval;
    reg [63:0] mscratch;

    assign nxtpc=ret?mepc:mtvec;
    assign jmp=ret||raise_intr;

    always @(*) case(csr_rd_addr)
        12'hf14: begin csr_data_native=64'h0; rd_err=0; end
        12'h341: begin csr_data_native=mepc; rd_err=0; end
        12'h300: begin csr_data_native=mstatus; rd_err=0; end
        12'h342: begin csr_data_native=mcause; rd_err=0; end
        12'h305: begin csr_data_native=mtvec; rd_err=0; end
        12'h304: begin csr_data_native=mie; rd_err=0; end
        12'h344: begin csr_data_native=mip; rd_err=0; end
        12'h343: begin csr_data_native=mtval; rd_err=0; end
        12'h340: begin csr_data_native=mscratch; rd_err=0; end
        default: begin csr_data_native=64'h0; rd_err=1; end
    endcase

    assign csr_data=(csr_rd_addr==csr_wr_addr&&wen)?in_data:csr_data_native;

    assign wr_err=wen&&
                    (csr_wr_addr!=12'h341)&&
                    (csr_wr_addr!=12'h300)&&
                    (csr_wr_addr!=12'h342)&&
                    (csr_wr_addr!=12'h305)&&
                    (csr_wr_addr!=12'h304)&&
                    (csr_wr_addr!=12'h340)&&
                    (csr_wr_addr!=12'h343)&&
                    (csr_wr_addr!=12'h344)&&
                    (csr_wr_addr!=12'hf14);

    always @(posedge clk) begin
        if(rst) begin
            mstatus<=64'ha0001800;
            mie<=64'h0;
            mip<=64'h0;
        end else begin
            if(ret) begin
                mstatus[12:11]<=2'b00;
                mstatus[3]<=mstatus[7];
                mstatus[7]<=1'b1;
            end else begin
                if(wen) begin 
                    case(csr_wr_addr)
                        12'h341: mepc<=in_data;
                        12'h300: mstatus<=in_data;
                        12'h342: mcause<=in_data;
                        12'h305: mtvec<=in_data;
                        12'h304: mie<=in_data;
                        12'h340: mscratch<=in_data;
                        12'h343: mtval<=in_data;
                        12'h344: mip<=in_data;
                        default: begin end
                    endcase
                    //$display("csr_addr=%h,in_data=%h",csr_wr_addr,in_data);
                end else begin
                    if(raise_intr) begin
                        //$display("raise_intr,wen=%b",wen);
                        mcause <= NO;
                        mepc <= pc;
                        mtval <= tval;
                        mstatus[12:11]<=2'b11;
                        mstatus[7]<=mstatus[3];
                        mstatus[3]<=1'b0;
                        mip[7]<=NO[63];  
                    end else if(clear_mip) mip[7]<=0;
                end
            end
        end
    end

    always @(*) begin
        `ifdef INSTR
        if(~rst&&~clk&&wen) $display("CSR:write %h",csr_wr_addr);
        `endif
    end 

endmodule

module ysyx_040066_csrwork(
    input [63:0] csr_data,
    input [63:0] rs1,
    input [4:0] zimm,
    input [2:0] csrctl,
    
    output reg [63:0] data
);
    wire [63:0] data2;
    assign data2=csrctl[2]?{59'b0,zimm}:rs1;
    always @(*) case(csrctl[1:0])
        2'b01: data=data2;
        2'b10: data=csr_data|data2;
        2'b11: data=csr_data&~data2;
        default: data=64'h114514;
    endcase

    always@(*) begin
//        $display("csrctl=%h,csr_data=%h,data2=%h,data=%h",csrctl,csr_data,data2,data);
    end
endmodule
