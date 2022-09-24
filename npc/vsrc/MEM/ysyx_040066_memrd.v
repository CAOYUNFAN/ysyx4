module ysyx_040066_memrd (
    input clk,rst,MemRd,
    input [63:0] addr,
    output reg [63:0] data,
    output reg error,
    output valid
);
    import "DPI-C" function void data_read(
        input longint raddr, output longint rdata, output byte valid
    );
    
    assign valid=1;
    reg [7:0] error_native;
    reg [63:0] data_temp;

    always @(negedge clk) begin
        data_read(addr,data_temp,error_native);
//        $display("ALL memrd:addr=%h,data=%h",addr,data_temp);
    end

    always @(posedge clk) begin
        data<=data_temp;
        error<=error_native[0];
        //$display("pos memrd:addr=%h,data=%h",addr,data_temp);
    end
endmodule


module ysyx_040066_imem (
    input clk,rst,
    input [63:0] pc,
    output [31:0] instr,
    output error,valid
);
    wire [63:0] instr_long;
    ysyx_040066_memrd imem(
        .clk(clk),.rst(rst),.MemRd(1),
        .error(error),.valid(valid),
        .addr(pc),.data(instr_long)
    );

    reg pc_2;
    always @(posedge clk) pc_2<=pc[2];

    assign instr=pc_2?instr_long[63:32]:instr_long[31:0];
endmodule

module ysyx_040066_dmem_rd (
    input clk,rst,MemRd,
    input [63:0] addr,
    output reg [63:0] data,
    output error,valid
);
    ysyx_040066_memrd dmemrd(
        .clk(clk),.rst(rst),.MemRd(MemRd),
        .error(error),.valid(valid),
        .addr(addr),.data(data)
    );
endmodule