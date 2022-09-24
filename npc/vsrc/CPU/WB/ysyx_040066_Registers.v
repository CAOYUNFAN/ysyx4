module ysyx_040066_Registers(
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

/*    input [4:0] multi_rd1,
    input [4:0] multi_rd2,
    input multi_valid1,multi_valid2,
    input [63:0] multi_result,

    input [4:0] div_rd1,
    input [4:0] div_rd2,
    input div_valid1,div_valid2,
    input [63:0] div_result,*/

    input [4:0] rs1,
    output reg rs1_valid,

    input [4:0] rs2,
    output reg rs2_valid
);
    ysyx_040066_Regs module_regs(
        .clk(clk),.wdata(data),.waddr(rd),.wen(wen&&rd!=5'b00000)
    );
    
    reg [63:0] src1;
    reg [63:0] src2;

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
        end else if(rs1==rd&&wen) begin
            src1=data;
            rs1_valid=1;
        end else begin
            src1=module_regs.rf[rs1];
            rs1_valid=1;
        end
    end

    always @(*) begin
        if(rs2==5'b00000) begin 
            src2=64'h0;
            rs2_valid=1;
        end else if(rs2==ex_rd&&ex_wen) begin
            src2=ex_data;
            rs2_valid=ex_valid;
        end else if(rs2==m_rd&&m_wen) begin
            src2=m_data;
            rs2_valid=m_valid;
        end else if(rs2==rd&&wen) begin
            src2=data;
            rs2_valid=1;
        end else begin 
            src2=module_regs.rf[rs2];
            rs2_valid=1;
        end
    end
endmodule