module ysyx_220066_memwr (
    input clk,rst,MemWr,
    input [63:0] addr,
    input [2:0] MemOp,
    input [63:0] data,
);
    reg [7:0] wmask;
    always @(*) case (MemOp)
        3'b000: begin
            wmask[0]=(addr[2:0]==3'o0);
            wmask[1]=(addr[2:0]==3'o1);
            wmask[2]=(addr[2:0]==3'o2);
            wmask[3]=(addr[2:0]==3'o3);
            wmask[4]=(addr[2:0]==3'o4);
            wmask[5]=(addr[2:0]==3'o5);
            wmask[6]=(addr[2:0]==3'o6);
            wmask[7]=(addr[2:0]==3'o7);
        end
        3'b001: begin
            wmask[0]=(addr[2:1]==2'o0);
            wmask[1]=(addr[2:1]==2'o0);
            wmask[2]=(addr[2:1]==2'o1);
            wmask[3]=(addr[2:1]==2'o1);
            wmask[4]=(addr[2:1]==2'o2);
            wmask[5]=(addr[2:1]==2'o2);
            wmask[6]=(addr[2:1]==2'o3);
            wmask[7]=(addr[2:1]==2'o3);
        end
        3'b010: begin
            wmask[3:0]={4{~addr[2]}};
            wmask[7:4]={4{addr[2]}};
        end
        default: begin
            wmask=8'hff;
        end
    endcase

    import "DPI-C" function void data_write(
        input longint waddr, input longint data, input byte mask
    );

    always @(posedge clk) begin
    //    if(!rst&&MemWr)$display("pc=%h,addr=%h,MemOp=%h,wmask=%h,data=%h",pc,addr,MemOp,wmask,data_Wr);
        if(!rst&&MemWr) data_write(addr,data,wmask);
    end
endmodule