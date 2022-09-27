// Burst types
`define AXI_BURST_TYPE_FIXED                                2'b00               //突发类型  FIFO
`define AXI_BURST_TYPE_INCR                                 2'b01               //ram  
`define AXI_BURST_TYPE_WRAP                                 2'b10
// Memory types (AR)
`define AXI_ARCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_ARCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_ARCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b1110
`define AXI_ARCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_ARCACHE_WRITE_BACK_NO_ALLOCATE                  4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_ALLOCATE                4'b1111
`define AXI_ARCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111

`define AXI_SIZE_BYTES_1                                    3'b000                //突发宽度一个数据的宽度
`define AXI_SIZE_BYTES_2                                    3'b001
`define AXI_SIZE_BYTES_4                                    3'b010
`define AXI_SIZE_BYTES_8                                    3'b011
`define AXI_SIZE_BYTES_16                                   3'b100
`define AXI_SIZE_BYTES_32                                   3'b101
`define AXI_SIZE_BYTES_64                                   3'b110
`define AXI_SIZE_BYTES_128                                  3'b111

module ysyx_040066 # (
    parameter RW_DATA_WIDTH     = 64,
    parameter RW_ADDR_WIDTH     = 32,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_ID_WIDTH      = 4,
    parameter AXI_STRB_WIDTH    = AXI_DATA_WIDTH/8
)(
    input                               clock,
    input                               reset,
    input                               io_interrupt,

    // AXI-master
    input                               io_master_awready,              
    output                              io_master_awvalid,
    output [AXI_ADDR_WIDTH-1:0]         io_master_awaddr,
    output [AXI_ID_WIDTH-1:0]           io_master_awid,
    output [7:0]                        io_master_awlen,
    output [2:0]                        io_master_awsize,
    output [1:0]                        io_master_awburst,

    input                               io_master_wready,                
    output                              io_master_wvalid,
    output [AXI_DATA_WIDTH-1:0]         io_master_wdata,
    output [AXI_DATA_WIDTH/8-1:0]       io_master_wstrb,
    output                              io_master_wlast,
    
    output                              io_master_bready,                
    input                               io_master_bvalid,
    input  [1:0]                        io_master_bresp,                 
    input  [AXI_ID_WIDTH-1:0]           io_master_bid,

    input                               io_master_arready,                
    output                              io_master_arvalid,
    output [AXI_ADDR_WIDTH-1:0]         io_master_araddr,
    output [AXI_ID_WIDTH-1:0]           io_master_arid,
    output [7:0]                        io_master_arlen,
    output [2:0]                        io_master_arsize,
    output [1:0]                        io_master_arburst,
    
    output                              io_master_rready,                 
    input                               io_master_rvalid,                
    input  [1:0]                        io_master_rresp,
    input  [AXI_DATA_WIDTH-1:0]         io_master_rdata,
    input                               io_master_rlast,
    input  [AXI_ID_WIDTH-1:0]           io_master_rid,

    //AXI_slave
    output io_slave_awready,
    input io_slave_awvalid,
    input [AXI_ADDR_WIDTH-1:0] io_slave_awaddr,
    input [AXI_ID_WIDTH-1:0] io_slave_awid,
    input [7:0] io_slave_awlen,
    input [2:0] io_slave_awsize,
    input [1:0] io_slave_awburst,

    output io_slave_wready,
    input io_slave_wvalid,
    input [AXI_DATA_WIDTH-1:0] io_slave_wdata,
    input [AXI_DATA_WIDTH/8-1:0] io_slave_wstrb,
    input io_slave_wlast,

    input io_slave_bready,
    output io_slave_bvalid,
    output [1:0] io_slave_bresp,
    output [AXI_ID_WIDTH-1:0] io_slave_bid,

    output io_slave_arready,
    input io_slave_arvalid,
    input [AXI_ADDR_WIDTH-1:0] io_slave_araddr,
    input [AXI_ID_WIDTH-1:0] io_slave_arid,
    input [7:0] io_slave_arlen,
    input [2:0] io_slave_arsize,
    input [1:0] io_slave_arburst,
);
    
    assign io_slave_awready=0;
    assign io_slave_wready=0;
    assign io_slave_bvalid=0;
    assign io_slave_bresp=2'b11;
    assign io_slave_bid={AXI_ID_WIDTH{1'b0}};
    assign io_slave_arready=0;
    

    reg [511:0] rd_data;
    reg [511:0] ins_data;
    wire [511:0] wr_data;

    wire ins_req,ins_burst,ins_valid,ins_err,ins_last;
    wire [63:0] ins_addr;

    wire rd_req,rd_burst,rd_ready,rd_err,rd_last;
    wire [2:0] rd_len;
    wire [63:0] rd_addr;

    wire wr_req,wr_burst,wr_ready,wr_err;
    wire [2:0] wr_len;
    wire [7:0] wr_mask;
    wire [63:0] wr_addr;

    wire rst; assign rst=~reset;
    ysyx_220066_top top(
        .clk(clock),.rst(rst),
        .ins_req(ins_req),.ins_burst(ins_burst),.ins_addr(ins_addr),.ins_last(ins_last),
        .ins_ready(ins_ready),.ins_err(ins_err),.ins_data(ins_data),

        .rd_req(rd_req),.rd_burst(rd_burst),.rd_len(rd_len),.rd_addr(rd_addr),.rd_last(rd_last),
        .rd_ready(rd_ready),.rd_err(rd_err),.rd_data(rd_data),

        .wr_req(wr_req),.wr_burst(wr_burst),.wr_len(wr_len),.wr_addr(wr_addr),
        .wr_ready(wr_ready),.wr_err(wr_err),.wr_mask(wr_mask),.wr_data(wr_data),

        .dbg_regs(),.mepc(),.mstatus(),.mcause(),.mtvec(),
        .error(),.done(),.valid()
    );

    // ------------------State Machine------------------TODO
    
    reg ins_available,rd_available;
    wire is_ins,is_rd,ins_done,rd_done;
    assign is_ins=ins_req&&ins_available;
    assign is_rd=rd_req&&rd_available&&~is_ins;
    always @(posedge clk)begin
        if(rst) {ins_available,rd_available}<=2'b11;
        else begin
            if(is_ins&&io_master_arready) ins_available<=1'b0;
            else if(ins_done) ins_available<=1'b1;

            if(is_rd&&io_master_arready) rd_available<=1'b0;
            else if(rd_done) rd_available<=1'b1;
        end
    end

    assign ins_done=(io_master_rvalid&&io_master_rlast&&io_master_rid[0]);
    assign rd_done=(io_master_rvalid&&io_master_rlast&&~io_master_rid[0]);
    
    reg [2:0] count;
    always @(posedge clk) begin
        if(rst) count<=3'b0;
        else if(wr_burst&&wr_req&&io_master_wready) count<=count+3'b1;
        else count<=3'b0;
    end

    // ------------------Write Transaction------------------
    wire [AXI_ID_WIDTH-1:0] axi_id              = {AXI_ID_WIDTH{1'b0}};
    // 写地址通道  以下没有备注初始化信号的都可能是你需要产生和用到的
    assign io_master_awvalid   = wr_req;
    assign io_master_awaddr    = wr_addr[31:0];
    assign io_master_awid      = axi_id;                                                                      //初始化信号即可
    assign io_master_awlen     = wr_burst?8'h7:8'b0;
    assign io_master_awsize    = wr_burst?`AXI_SIZE_BYTES_64:wr_len;
    assign io_master_awburst   = `AXI_BURST_TYPE_INCR;                                                          //初始化信号即可

    // 写数据通道
    assign io_master_wvalid    = wr_req;
    assign io_master_wdata     = wr_data[{count,3'h7}:{count,3'h0}] ;
    assign io_master_wstrb     = wr_burst?8'hff:wr_mask;
    assign io_master_wlast     = wr_burst||(count==3'h7);                                                    //初始化信号即可

    // 写应答通道
    assign io_master_bready    = 1'b1;

    // ------------------Read Transaction------------------

    // Read address channel signals
    assign io_master_arvalid   = ins_available||rd_available;
    assign io_master_araddr    = ins_available?ins_addr:rd_addr;
    assign io_master_arid      = {(AXI_ID_WIDTH-1){ins_available}};                                                                           //初始化信号即可                        
    assign io_master_arlen     = (ins_available&&ins_burst||rd_available&&rd_burst)?8'h7:8'h0;                                                                          
    assign io_master_arsize    = ins_available?(ins_burst?`AXI_SIZE_BYTES_64:`AXI_SIZE_BYTES_32):(rd_burst?`AXI_SIZE_BYTES_64:rd_len);
    assign io_master_arburst   = (ins_available&&ins_burst||rd_available&&rd_burst)?`AXI_BURST_TYPE_INCR:`AXI_BURST_TYPE_FIXED;
    
    // Read data channel signals
    assign io_master_rready    = 1'b1;

    always @(posedge clk) if(io_master_rvalid) begin
        
    end

endmodule