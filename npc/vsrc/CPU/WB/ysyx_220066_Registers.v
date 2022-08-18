module ysyx_220066_Registers(
    input clk,rst,
    input wen,
    input [4:0] rd,
    input [63:0] data,

    input [4:0] ex_rd,
    input ex_wen,
    input ex_valid,
    input [63:0] ex_data,

    input [4:0] m_rd,
    input m_wen,
    input m_valid,
    input [63:0] m_data,

    input [4:0] rs1,
    output reg [63:0] src1,
    output reg rs1_valid,

    input [4:0] rs2,
    output reg [63:0] src2,
    output reg rs2_valid
);
    ysyx_220066_Regs regs(
        .clk(clk),.wdata(data),.waddr(rd),.wen(wen&&rd!=5'b00000)
    );
    always @(*) begin
        if(rs1==5'b00000) begin 
            src1=64'h0;
            rs1_valid=1;
        end else if(rs1==ex_rd&&ex_wen) begin
            src1=ex_data;
            rs1_valid=ex_valid;
        end else if(rs1==m_rd&&m_wen) begin
            src1=m_data;
            rs1_valid=m_valid;
        end else src1=regs.rf[rs1];
    end

    always @(*) begin
        if(rs2==5'b00000) begin 
            src2=64'h0;
            rs2_valid=1;
        end else if(rs2==ex_rd&&ex_wen) begin
            src2=ex_data;
            rs1_valid=ex_valid;
        end else if(rs2==m_rd&&m_wen) begin
            src2=m_data;
            rs2_valid=m_valid;
        end else src2=regs.rf[rs1];
    end
endmodule
