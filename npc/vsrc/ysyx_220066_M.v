module ysyx_220066_M (
    input MemToReg,
    input [63:0] ALUout,

    input [63:0] data_read,
    output [63:0] m_out
    );

    assign m_out=MemToReg?data_read:ALUout;

    always @(*) begin
        $display("m_out=%h,ALUout=%h",m_out,ALUout);
    end

endmodule
