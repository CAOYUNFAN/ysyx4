module ysyx_220066_cache #(TAG_LEN=21,IDNEX_LEN=5,OFFSET_LEN=3,INDEX_NUM=64,LINE_LEN=512)(
    input clk,rst,force_update,

    //CPU
    //[63:32] [31:11] [10:6] [5:3] [2:0]
    input valid,op,//op 0:read,1:write
    input [IDNEX_LEN-1:0] index,
    input [TAG_LEN-1:0] tag,
    input [OFFSET_LEN-1:0] offset,
    input [7:0] wstrb,
    input [63:0] wdata,
    output ok,
    output ready,
    output reg [63:0] rdata,
    reg rw_error,
    input fence,

    //AXI
    output reg [31:0] addr,
    output reg rd_req,
    input rd_ready,
    input rd_error,
    input [LINE_LEN-1:0] rd_data,
    output reg wr_req,
    output [LINE_LEN-1:0] wr_data,
    input wr_ready,wr_error
);
    wire uncache;
    assign uncache=~tag[TAG_LEN-1]&&valid;
    //data:
    reg [TAG_LEN-1:0] cache_tag [INDEX_NUM-1:0];
    reg [INDEX_NUM-1:0] cache_valid;
    reg [INDEX_NUM-1:0] cache_dirty;
    reg [INDEX_NUM-1:0] cache_error;
    reg [(INDEX_NUM/2)-1:0] cache_freq;
    //control
    reg [1:0] status;//00:valid,10:waiting for read,11:wating for write,01:fence
    reg [IDNEX_LEN:0] count;

    wire hit,hit_0,hit_1;
    assign hit_0=(tag==cache_tag[{index,1'b0}])&&cache_valid[{index,1'b0}];
    assign hit_1=(tag==cache_tag[{index,1'b1}])&&cache_valid[{index,1'b1}];
    assign hit=(hit_0||hit_1)&&(status==2'b00);
    wire miss,refill_pos,dirty;
    assign miss=~hit_0&&~hit_1&&(status==2'b00);
    assign refill_pos=(~cache_valid[{index,1'b0}]||~cache_valid[{index,1'b1}])?cache_valid[{index,1'b0}]:
                    ( (cache_dirty[{index,1'b0}]^cache_dirty[{index,1'b1}])?cache_dirty[{index,1'b0}]:~cache_freq[index] );
    assign dirty=cache_dirty[{index,refill_pos}]&&cache_valid[{index,refill_pos}];
    assign ready=(status!=2'b01);

    wire ready_to_read,ready_to_write;
    assign ready_to_read=rd_req&&rd_ready;
    assign ready_to_write=wr_ready&&wr_req;

    reg uncached_done;
    always @(posedge clk) begin
        if(rst) status<=2'b00;
        else if(fence&&status==2'b00) status<=2'b01;
        else if(valid&&miss&&~uncached_done) status<={1'b1,uncache?op:dirty};
        else if(ready_to_read) status<=2'b00;
        else if(status==2'b11&&ready_to_write) status<=uncache?2'b00:2'b10;
        else if(status==2'b01&&(&count)&&(ready_to_write||~cache_dirty[{(IDNEX_LEN+1){1'b1}}]||~cache_valid[{(IDNEX_LEN+1){1'b1}}])) status<=2'b00;
    end

    reg nxt_clear;
    always @(posedge clk)begin
        if(rst||(rd_req&&ready_to_read)) nxt_clear<=0;
        else if(rd_req&&force_update) nxt_clear<=1; 
    end

    wire [LINE_LEN-1:0] rd;

    reg [63:0] uncached_data;
    always @(posedge clk) uncached_data<=rd_data[63:0];
    always @(posedge clk) uncached_done<=~rst&&uncache&&(ready_to_read&&status==2'b10||ready_to_write&&status==2'b11)&&~nxt_clear;

    assign ok=uncache?uncached_done:hit;

    reg [OFFSET_LEN-1:0] offset_native;
    always@(posedge clk) offset_native<=offset;

    always @(*) begin 
        if(uncache) rdata=uncached_data; 
        else case (offset_native)
            3'b000:rdata=rd[ 63:  0];
            3'b001:rdata=rd[127: 64];
            3'b010:rdata=rd[191:128];
            3'b011:rdata=rd[255:192];
            3'b100:rdata=rd[319:256];
            3'b101:rdata=rd[383:320];
            3'b110:rdata=rd[447:384];
            3'b111:rdata=rd[511:448];
        endcase
    end
    assign wr_data=uncache?{rd[511:64],wdata}:rd;
    always @(posedge clk) rw_error<=uncache&&(op?wr_error:rd_error);

    `ifdef R_W
    //integer xx;
    `endif

    always @(posedge clk) begin
        if(rst||force_update) begin
            cache_valid<={INDEX_NUM{1'b0}};
            cache_freq<={(INDEX_NUM/2){1'b0}};
        end else if(valid&&hit) begin
            if(op) begin
                cache_dirty[{index,hit_1}]<=1;
                `ifdef R_W
                $display("simple write on %b,tag=%h,index=%h,offset=%h,data=%h,wmask=%b,hit_0=%b,tt=%h",hit_1,tag,index,offset,wdata,wstrb,hit_0,cache_tag[{index,hit_1}]);
                `endif
            end
            cache_freq[index]<=hit_1;
        end else if(ready_to_read&&~uncache) begin
            //cache_data[{index,refill_pos}]<=rd_data;
            cache_tag[{index,refill_pos}]<=tag;
            cache_valid[{index,refill_pos}]<=~nxt_clear;
            cache_dirty[{index,refill_pos}]<=0;
            `ifdef R_W
            $display("Read on %b tag=%h,index=%h",refill_pos,tag,index);
            //for(xx=0;xx<8;xx=xx+1) $display("rd_data[%d]=%h",xx[2:0],rd_data[{509'h0,xx[2:0]}*{512'd64}+{512'd63}:{509'h0,xx[2:0]}*{512'd64}]);
            `endif
        end else if(ready_to_write) begin
            if(status==2'b11&&~uncache) cache_dirty[{index,refill_pos}]<=0;
            else if(status==2'b01) cache_dirty[count]<=0;
            `ifdef R_W
            $display("Write on %b tag=%h,index=%h",refill_pos,tag,index);
            //for(xx=0;xx<8;xx++) $display("wr_data[%d]=%h",xx[2:0],wr_data[{509'h0,xx[2:0]}*{512'd64}+{512'd63}:{509'h0,xx[2:0]}*{512'd64}]);
            `endif
        end
    end

    always @(posedge clk) begin
        if(rst||status!=2'b01) count<={(IDNEX_LEN+1){1'b0}};
        else count<=count+{{IDNEX_LEN{1'b0}},ready_to_write||~cache_dirty[count]||~cache_valid[count]};
    end

    reg start_fence;
    always @(posedge clk) start_fence<=fence&&(status==2'b00);

    always @(posedge clk) begin
        if(rst) {rd_req,wr_req}<=2'b00;
        else if(valid&&miss&&~uncached_done) begin
            rd_req<=uncache?~op:~dirty;
            wr_req<=uncache?op:dirty;
            addr<={dirty&&~uncache?cache_tag[{index,refill_pos}]:tag,index,6'b0};
        end else if(status==2'b11&&ready_to_write) begin
            rd_req<=~uncache;wr_req<=0;
            addr<={tag,index,6'b0};
        end else if(ready_to_read) begin
            rd_req<=0;
        end else if(status==2'b01) begin
            addr<={cache_tag[count],count[IDNEX_LEN:1],6'b0};
            wr_req<=cache_valid[count]&&cache_dirty[count]&&~ready_to_write&&~start_fence;
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
            .Q(Q),.CLK(clk),.CEN(1'b0),.BWEN(~BWEN),.D(D),
            .WEN((~(valid&&hit&&op)&&~ready_to_read)||rst||uncache),
            .A((status==2'b01)?count:{index,hit?hit_1:refill_pos})
        );
        for(y=0;y<64;y=y+1) begin
            assign rd[x*2+1+y*8:x*2+y*8]=Q[y*2+1:y*2];
            assign D[y*2+1:y*2]=(ready_to_read?rd_data[x*2+1+y*8:x*2+y*8]:wrr_data[x*2+1+y*8:x*2+y*8]);
        end
    end endgenerate

    always @(*) begin
        `ifdef fully_info
        if(~rst&&~clk)begin
            $display("Cache:status=%b,tag=%h,index=%h,hit_0=%b,hit_1=%b,uncache=%b,valid=%b",status,tag,index,hit_0,hit_1,uncache,valid);
            //$display("Cache:wen=%h,rd=%h",BWEN,rd);
        end
        `endif
    end
endmodule