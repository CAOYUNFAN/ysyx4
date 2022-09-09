module ysyx_220066_cache #(TAG_LEN=21,IDNEX_LEN=5,OFFSET_LEN=3,INDEX_NUM=64,LINE_LEN=512)(
    input clk,rst,

    //CPU
    //[63:12] [11:4] [3:3] [2:0]
    input valid,op,//op 0:read,1:write
    input [IDNEX_LEN-1:0] index,
    input [TAG_LEN-1:0] tag,
    input [OFFSET_LEN-1:0] offset,
    input [7:0] wstrb,
    input [63:0] wdata,
    output ok,
    output reg [63:0] rdata,
    output reg rw_error,
    input fence,

    //AXI
    output reg [31:0] addr,
    output reg rd_req,
    input rd_ready,
    input rd_valid,
    input [LINE_LEN-1:0] rd_data,
    output reg wr_req,
    output [LINE_LEN-1:0] wr_data,
    input wr_ready
);
    //data:
    reg [TAG_LEN-1:0] cache_tag [INDEX_NUM-1:0];
//    reg [127:0] cache_data [INDEX_NUM-1:0];

    reg [INDEX_NUM-1:0] cache_valid;
    reg [INDEX_NUM-1:0] cache_dirty;
    reg [INDEX_NUM-1:0] cache_error;
    reg [(INDEX_NUM/2)-1:0] cache_freq;
    //control
    reg [1:0] status;//00:valid,10:waiting for read,11:wating for write,01:fence
    reg [IDNEX_LEN:0] count;

    wire hit_0,hit_1;
    assign hit_0=(tag==cache_tag[{index,1'b0}])&&cache_valid[{index,1'b0}];
    assign hit_1=(tag==cache_tag[{index,1'b1}])&&cache_valid[{index,1'b1}];
    assign ok=(hit_0||hit_1)&&(status==2'b00);
    wire miss,refill_pos,dirty;
    assign miss=~hit_0&&~hit_1&&(status==2'b00);
    assign refill_pos=(~cache_valid[{index,1'b0}]||~cache_valid[{index,1'b1}])?cache_valid[{index,1'b0}]:
                    ( (cache_dirty[{index,1'b0}]^cache_dirty[{index,1'b1}])?cache_dirty[{index,1'b0}]:~cache_freq[index] );
    assign dirty=cache_dirty[{index,refill_pos}]&&cache_valid[{index,refill_pos}];

    wire ready_to_read,ready_to_write;
    assign ready_to_read=rd_req&&rd_ready;
    assign ready_to_write=wr_ready&&wr_req;

    always @(posedge clk) begin
        if(rst) status<=2'b00;
        else if(fence&&status==2'b00) status<=2'b01;
        else if(valid&&miss) status<={1'b1,dirty};
        else if(ready_to_read) status<=2'b00;
        else if(status==2'b11&&ready_to_write) status[0]<=1'b0;
        else if(status==2'b01&&(&count)&&(ready_to_write||~cache_dirty[{(IDNEX_LEN+1){1'b1}}]||~cache_valid[{(IDNEX_LEN+1){1'b1}}])) status<=2'b00;
    end

    wire [LINE_LEN-1:0] rd;
    always @(*) case (offset)
        3'b000:rdata=rd[ 63:  0];
        3'b001:rdata=rd[127: 64];
        3'b010:rdata=rd[191:128];
        3'b011:rdata=rd[255:192];
        3'b100:rdata=rd[319:256];
        3'b101:rdata=rd[383:320];
        3'b110:rdata=rd[447:384];
        3'b111:rdata=rd[511:448];
    endcase
    assign wr_data=rd;

    always @(posedge clk) if(valid&&ok&&~op)
        rw_error<=cache_error[{index,hit_1}];

    always @(posedge clk) begin
        if(rst) begin
            cache_valid<={INDEX_NUM{1'b0}};
            cache_freq<={(INDEX_NUM/2){1'b0}};
        end else if(valid&&ok) begin
            if(op) begin
                /*if(wstrb[0]&&~offset) cache_data[{index,hit_1}][  7:  0] <= wdata[ 7: 0] ;
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
                if(wstrb[7]&& offset) cache_data[{index,hit_1}][127:120] <= wdata[63:56] ;*/
                cache_dirty[{index,hit_1}]<=1;
                `ifdef R_W
                $display("simple write on %b,tag=%h,index=%h,offset=%h,data=%h,wmask=%b,hit_0=%b,tt=%h",hit_1,tag,index,offset,wdata,wstrb,hit_0,cache_tag[{index,hit_1}]);
                `endif
            end
            cache_freq[index]<=hit_1;
        end else if(ready_to_read) begin
            //cache_data[{index,refill_pos}]<=rd_data;
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
        if(rst||status!=2'b01) count<={(IDNEX_LEN+1){1'b0}};
        else count<=count+{{IDNEX_LEN{1'b0}},ready_to_write||~cache_dirty[count]||~cache_valid[count]};
    end

    reg read_ready,write_ready;
    always @(posedge clk) begin
        read_ready<=ready_to_read;
        write_ready<=ready_to_write;
    end

    always @(posedge clk) begin
        if(rst) {rd_req,wr_req}<=2'b00;
        else if(valid&&miss) begin
            rd_req<=~dirty;
            wr_req<=dirty;
            addr<={dirty?cache_tag[{index,refill_pos}]:tag,index,6'b0};
        end else if(status==2'b11&&ready_to_write) begin
            rd_req<=1;wr_req<=0;
            addr<={tag,index,6'b0};
        end else if(ready_to_read) begin
            rd_req<=0;
        end else if(status==2'b01) begin
            addr<={cache_tag[count],count[IDNEX_LEN:1],6'b0};
            wr_req<=cache_valid[count]&&cache_dirty[count]&&~ready_to_write;
        end
    end

    wire [127:0] BWEN;
    genvar i,j;
    generate for(i=0;i<8;i=i+1) for(j=0;j<8;j=j+1) 
        assign BWEN[j*2+1+i*16:j*2+i*16]={2{ready_to_read?1'b1:(offset==i[2:0])&&wstrb[j]}};     
    endgenerate    

    wire [LINE_LEN-1:0] wrr_data;
    assign wrr_data={8{wdata}};
    genvar x,y;generate for(x=0;x<4;x=x+1)begin:ram
        wire [127:0] Q,D;
        S011HD1P_X32Y2D128_BW ram_data(
            .Q(Q),.CLK(clk),.CEN(1'b1),.BWEN(BWEN),.D(D),
            .WEN(((valid&&ok&&op)||ready_to_read)&&~rst),
            .A({index,ready_to_read?refill_pos:hit_1})
        );
        for(y=0;y<64;y=y+1) begin
            assign rd[x*2+1+y*8:x*2+y*8]=Q[y*2+1:y*2];
            assign D[y*2+1:y*2]=(ready_to_read?rd_data[x*2+1+y*8:x*2+y*8]:wrr_data[x*2+1+y*8:x*2+y*8]);
        end
    end endgenerate

    always @(*) begin
        `ifdef fully_info
        if(~rst&&~clk)$display("Cache:status=%b,rd_req=%b,wr_req=%b,refill_pos=%b,hit_0=%b,hit_1=%b,tag_0=%h,tag_1=%h,index=%h,tag=%h,ready_to_read=%b",status,rd_req,wr_req,refill_pos,hit_0,hit_1,cache_tag[{index,1'b0}],cache_tag[{index,1'b1}],index,tag,ready_to_read);
        `endif
    end
endmodule