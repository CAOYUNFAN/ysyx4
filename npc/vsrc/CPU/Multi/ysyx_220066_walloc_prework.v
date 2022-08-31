module ysyx_220066_walloc_prework(
    input [129:0] src,
    input [2:0] sel,
    output reg [129:0] data,
    output cout 
);
    assign cout=sel[2]&&(~sel[1]||~sel[0]);
    always @(*) case(sel)
        3'b000,3'b111:data=130'h0;
        3'b001,3'b010:data=src;
        3'b101,3'b110:data=~src;
        3'b011:data={src[128:0],1'b0};
        3'b100:data={~src[128:0],1'b1};
    endcase
endmodule