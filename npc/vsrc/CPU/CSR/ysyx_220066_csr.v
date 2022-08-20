module ysyx_220066_csr (
    input rst,clk,
    input [11:0] csr_rd_addr,
    input [11:0] csr_wr_addr,
    input wen,
    input [63:0] in_data,
    output reg [63:0] csr_data,
    output reg rd_err,
    output wr_err,//for csr instruction
    
    input raise_intr,
    input [63:0] NO,
    input [63:0] pc,

    input ret,

    output jmp,
    output [63:0] nxtpc
);
    reg [63:0] mepc;
    reg [63:0] mstatus;
    reg [63:0] mcause;
    reg [63:0] mtvec;

    assign nxtpc=ret?mepc:mtvec;
    assign jmp=ret||raise_intr;

    always @(*) case(csr_rd_addr)
        12'h341: begin csr_data=mepc; rd_err=0; end
        12'h300: begin csr_data=mstatus; rd_err=0; end
        12'h342: begin csr_data=mcause; rd_err=0; end
        12'h305: begin csr_data=mtvec; rd_err=0; end
        default: begin csr_data=64'h0; err=1; end
    endcase

    assign wr_err=wen&&
                    (csr_wr_addr!=12'h341)&&
                    (csr_wr_addr!=12'h300)&&
                    (csr_wr_addr!=12'h342)&&
                    (csr_wr_addr!=12'h305);

    always @(posedge clk) begin
        if(rst) begin
            mstatus=64'ha0001800;
        end else begin
            if(ret) begin
                mstatus[12:11]=2'b00;
                mstatus[3]=mstatus[7];
                mstatus[7]=1'b1;
            end else begin
                if(wen) begin 
                    case(csr_wr_addr)
                        12'h341: mepc=in_data;
                        12'h300: mstatus=in_data;
                        12'h342: mcause=in_data;
                        12'h305: mtvec=in_data;
                        default: begin end
                    endcase
                    //$display("csr_addr=%h,in_data=%h",csr_addr,in_data);
                end else begin
                    if(raise_intr) begin
                        //$display("raise_intr,wen=%b",wen);
                        mcause = NO;
                        mepc = pc;
                        mstatus[12:11]=2'b11;
                        mstatus[7]=mstatus[3];
                        mstatus[3]=1'b0;    
                    end
                end
            end
        end
    end

endmodule

module ysyx_220066_csrwork(
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