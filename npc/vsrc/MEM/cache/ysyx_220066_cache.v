module ysyx_220066_cache (
    input clk,rst,

    //CPU
    //[63:12] [11:4] [3:3] [2:0]
    input valid,op,//op 0:read,1:write
    input [6:0] index,
    input [52:0] tag,
    input offset,
    input [7:0] wstrb,
    input [63:0] wdata,
    output ok,
    output reg [63:0] rdata,
    input fence,

    //AXI
    output rd_req,
    output [63:0] rd_addr,
    input rd_ready,
    input rd_valid,
    input [127:0] rd_data,
    output wr_req,
    output [63:0] wr_addr,
    output [127:0] wr_data,
    input wr_ready
);
    //data:
    reg [52:0] cache_tag [255:0];
    reg [127:0] cache_data [255:0];
    reg cache_valid [255:0];
    reg cache_dirty [255:0];
    reg cache_error [255:0];
    reg cache_freq [127:0];
    //control
    reg [1:0] status;//00:valid,10:waiting for read,11:wating for write,01:fence
    reg [7:0] count;

    wire hit_0,hit_1;
    assign hit_0=(tag==cache_tag[{index,1'b0}])&&cache_valid[{index,1'b0}];
    assign hit_1=(tag==cache_tag[{index,1'b1}])&&cache_valid[{index,1'b1}];
    assign ok=(hit_0||hit_1)&&(status==2'b00);
    wire refill_pos;
    assign refill_pos=(~cache_valid[{index,1'b0}]||~cache_valid[{index,1'b1}])?cache_valid[{index,1'b0}]:
                    ( (cache_dirty[{index,1'b0}]^cache_dirty[{index,1'b1}])?cache_dirty[{index,1'b0}]:~cache_freq[index] );

    wire ready_to_read,ready_to_write;
    assign ready_to_read=rd_req&&rd_ready&&status==2'b10;
    assign ready_to_write=wr_ready&&wr_req;

    always @(posedge clk) begin
        if(rst) status<=2'b00;
        else if(fence) status<=2'b01;
        else if(valid&&~ok) status<={1'b1,cache_dirty[{index,refill_pos}]};
        else if(status==2'b11&&ready_to_write) status[0]<=1'b0;
        else if(ready_to_read) status[1]<=1'b0;
        else if(status==2'b01&&count==8'hff&&(ready_to_write||~cache_dirty[8'hff])) status<=2'b00;
    end

    always @(posedge clk) begin
        if(valid&&ok&&~op) rdata<=cache_data[{index,hit_1}];
    end

    integer i;
    always @(posedge clk) begin
        if(rst) begin
            for(i=0;i<128;i=i+1) begin
                cache_valid[{i,1'b0}]<=0;
                cache_valid[{i,1'b1}]<=0;
                cache_freq[i]<=0;
            end
        end else if(valid&&ok) begin
            if(op) begin
                for(i=0;i<8;i=i+1) if(wstrb[i]) cache_data[{index,hit_1}][(i+offset*8+1)*8-1:(i+offset*8)*8]<=wdata[(i+1)*8-1:i*8];
                cache_dirty[{index,hit_1}]<=1;
            end
            cache_freq[index]<=hit_1;
        end else if(ready_to_read) begin
            cache_data[{index,refill_pos}]<=rd_data;
            cache_tag[{index,refill_pos}]<=tag;
            cache_valid[{index,refill_pos}]<=1;
            cache_dirty[{index,refill_pos}]<=0;
            cache_error[{index,refill_pos}]<=rd_valid;
        end else if(ready_to_write) begin
            if(status==2'b11) cache_dirty[{index,refill_pos}]<=0;
            else if(status==2'b01) cache_dirty[count]<=0;
        end
    end

    reg [59:0] addr_buf;
    assign rd_addr={addr_buf,4'h0};assign wr_addr={addr_buf,4'h0};

    always @(posedge clk) begin
        if(rst||status!=2'b01) count<=8'h00;
        else count<=count+{7'b0,ready_to_write||~cache_dirty[count]};
    end

    assign rd_req=~rst&&((valid&&~ok&&~cache_dirty[{index,refill_pos}])||(status==2'b10));
    assign rd_addr={tag,index,4'h0};
    assign wr_req=~rst&&((valid&&~ok&&~cache_dirty[{index,refill_pos}])||status[0]||fence);
    wire [7:0] pos; assign pos=(~status[1]||fence)?{index,refill_pos}:count;
    assign wr_addr={cache_tag[pos],index,4'h0};
    assign wr_data=cache_data[pos];

endmodule