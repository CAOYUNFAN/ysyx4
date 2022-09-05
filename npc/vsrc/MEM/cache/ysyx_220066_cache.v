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
    output reg rw_error,
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

    reg [255:0] cache_valid;
    reg [255:0] cache_dirty;
    reg [255:0] cache_error;
    reg [127:0] cache_freq;
    //control
    reg [1:0] status;//00:valid,10:waiting for read,11:wating for write,01:fence
    reg [7:0] count;

    wire hit_0,hit_1;
    assign hit_0=(tag==cache_tag[{index,1'b0}])&&cache_valid[{index,1'b0}];
    assign hit_1=(tag==cache_tag[{index,1'b1}])&&cache_valid[{index,1'b1}];
    assign ok=(hit_0||hit_1)&&(status==2'b00);
    wire miss=~hit_0&&~hit_1&&(status==2'b00);
    wire refill_pos;
    assign refill_pos=(~cache_valid[{index,1'b0}]||~cache_valid[{index,1'b1}])?cache_valid[{index,1'b0}]:
                    ( (cache_dirty[{index,1'b0}]^cache_dirty[{index,1'b1}])?cache_dirty[{index,1'b0}]:~cache_freq[index] );

    wire ready_to_read,ready_to_write;
    assign ready_to_read=rd_req&&rd_ready&&status==2'b10;
    assign ready_to_write=wr_ready&&wr_req;

    always @(posedge clk) begin
        if(rst) status<=2'b00;
        else if(fence) status<=2'b01;
        else if(valid&&miss) status<={1'b1,cache_dirty[{index,refill_pos}]&&cache_valid[{index,refill_pos}]};
        else if(status==2'b11&&ready_to_write) status[0]<=1'b0;
        else if(ready_to_read) status[1]<=1'b0;
        else if(status==2'b01&&count==8'hff&&(ready_to_write||~cache_dirty[8'hff]||~cache_valid[8'hff])) status<=2'b00;
    end

    always @(posedge clk) begin
        if(valid&&ok&&~op) begin 
            rdata<=offset?cache_data[{index,hit_1}][127:64]:cache_data[{index,hit_1}][63:0];
            rw_error<=cache_error[{index,hit_1}];
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            cache_valid<=256'b0;
            cache_freq<=128'b0;
        end else if(valid&&ok) begin
            if(op) begin
                if(wstrb[0]&&~offset) cache_data[{index,hit_1}][  7:  0] <= wdata[ 7: 0] ;
                if(wstrb[1]&&~offset) cache_data[{index,hit_1}][ 15:  8] <= wdata[15: 8] ;
                if(wstrb[2]&&~offset) cache_data[{index,hit_1}][ 23: 16] <= wdata[23:16] ;
                if(wstrb[3]&&~offset) cache_data[{index,hit_1}][ 31: 24] <= wdata[31:24] ;
                if(wstrb[4]&&~offset) cache_data[{index,hit_1}][ 39: 32] <= wdata[39:32] ;
                if(wstrb[5]&&~offset) cache_data[{index,hit_1}][ 47: 40] <= wdata[47:40] ;
                if(wstrb[6]&&~offset) cache_data[{index,hit_1}][ 55: 48] <= wdata[55:48] ;
                if(wstrb[7]&&~offset) cache_data[{index,hit_1}][ 63: 56] <= wdata[63:56] ;
                if(wstrb[0]&& offset) cache_data[{index,hit_1}][ 71: 64] <= wdata[ 7: 0] ;
                if(wstrb[1]&& offset) cache_data[{index,hit_1}][ 79: 72] <= wdata[15: 8] ;
                if(wstrb[2]&& offset) cache_data[{index,hit_1}][ 87: 80] <= wdata[23:16] ;
                if(wstrb[3]&& offset) cache_data[{index,hit_1}][ 95: 88] <= wdata[31:24] ;
                if(wstrb[4]&& offset) cache_data[{index,hit_1}][103: 96] <= wdata[39:32] ;
                if(wstrb[5]&& offset) cache_data[{index,hit_1}][111:104] <= wdata[47:40] ;
                if(wstrb[6]&& offset) cache_data[{index,hit_1}][119:112] <= wdata[55:48] ;
                if(wstrb[7]&& offset) cache_data[{index,hit_1}][127:120] <= wdata[63:56] ;
                cache_dirty[{index,hit_1}]<=1;
                `ifdef R_W
                $display("simple write on %b,tag=%h,index=%h,offset=%h,data=%h,wmask=%b,hit_0=%b,tt=%h",hit_1,tag,index,offset,wdata,wstrb,hit_0,cache_tag[{index,hit_1}]);
                `endif
            end
            cache_freq[index]<=hit_1;
        end else if(ready_to_read) begin
            cache_data[{index,refill_pos}]<=rd_data;
            cache_tag[{index,refill_pos}]<=tag;
            cache_valid[{index,refill_pos}]<=1;
            cache_dirty[{index,refill_pos}]<=0;
            cache_error[{index,refill_pos}]<=~rd_valid;
            `ifdef R_W
            $display("Read on %b tag=%h,index=%h,data=%h%h",refill_pos,tag,index,rd_data[127:64],rd_data[63:0]);
            `endif
        end else if(ready_to_write) begin
            if(status==2'b11) cache_dirty[{index,refill_pos}]<=0;
            else if(status==2'b01) cache_dirty[count]<=0;
            `ifdef R_W
            $display("Write on %b tag=%h,index=%h",refill_pos,tag,index);
            `endif
        end
    end

    always @(posedge clk) begin
        if(rst||status!=2'b01) count<=8'h00;
        else count<=count+{7'b0,ready_to_write||~cache_dirty[count]||~cache_valid[count]};
    end

    reg read_ready,write_ready;
    always @(posedge clk) begin
        read_ready<=ready_to_read;
        write_ready<=ready_to_write;
    end

    assign rd_req=~rst&&(
        (valid&&miss&&~(cache_dirty[{index,refill_pos}]&&cache_valid[{index,refill_pos}]))
        ||(status==2'b11&&ready_to_write)
        ||(status==2'b10&&~read_ready));
    assign rd_addr={tag,index,4'h0};

    assign wr_req=~rst&&(
        (valid&&miss&&cache_dirty[{index,refill_pos}]&&cache_valid[{index,refill_pos}])
        ||(status==2'b11&&~write_ready)
        ||(status==2'b01&&cache_valid[count]&&cache_dirty[count]));
    wire [7:0] pos; assign pos=(status!=2'b01)?{index,refill_pos}:count;
    assign wr_addr={cache_tag[pos],index,4'h0};
    assign wr_data=cache_data[pos];

    always @(*) begin
        `ifdef fully_info
        if(~rst&&~clk)$display("Cache:status=%b,rd_req=%b,wr_req=%b,refill_pos=%b,hit_0=%b,hit_1=%b,tag_0=%h,tag_1=%h,index=%h,tag=%h",status,rd_req,wr_req,refill_pos,hit_0,hit_1,cache_tag[{index,1'b0}],cache_tag[{index,1'b1}],index,tag);
        `endif
    end
endmodule