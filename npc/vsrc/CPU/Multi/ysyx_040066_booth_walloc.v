module ysyx_040066_booth_walloc(
    input clk,block,
    input [63:0] src1_in,//clk0
    input [63:0] src2_in,//clk0
    input [1:0] ALUctr_in,//clk0
    input [1:0] ALUctr,//clk1
    input is_w,//clk1

    output [63:0] result
);
    reg [129:0] x;
    reg [65:0] y;
    always @(posedge clk) if(~block) begin
        x[63:0]<=src1_in;
        x[129:64]<={66{src1_in[63]&&(ALUctr[1]^ALUctr[0])}};
        y[63:0]<=src2_in;
        y[65:64]<={2{src2_in[63]&&~ALUctr[1]}};
    end

    //pre_work
    wire [4289:0] part_group;
    wire [32:0] part_cout;
    ysyx_040066_walloc_prework part0(
        .src(x),.sel({y[1:0],1'b0}),
        .data(part_group[129:0]),.cout(part_cout[0])
    );

    genvar i;
    generate for(i=1;i<33;i=i+1) begin:gen_walloc_prework
        ysyx_040066_walloc_prework part(
            .src({x[129-2*i:0],{2*i{1'b0}}}),.sel(y[i*2+1:i*2-1]),
            .data(part_group[(i+1)*130-1:i*130]),.cout(part_cout[i])
        );
    end endgenerate
    
    //switch
    wire [4289:0] sw_group;
    ysyx_040066_switch switch(.part_group(part_group),.sw_group(sw_group));

    //walloc_tree
    wire [128:0] wt_c;
    wire [129:0] wt_s;
    /* verilator lint_off UNOPTFLAT */
    wire [29:0] wt_cout [128:0];

    ysyx_040066_walloc_33bits walloc0(
        .src_in(sw_group[32:0]),.cin(part_cout[29:0]),
        .cout_group(wt_cout[0]),.s(wt_s[0]),.cout(wt_c[0])
    );

    genvar j;
    generate for(j=1;j<129;j=j+1) begin:gen_walloc_tree
        ysyx_040066_walloc_33bits walloc(
            .src_in(sw_group[(j+1)*33-1:j*33]),.cin(wt_cout[j-1]),
            .cout_group(wt_cout[j]),.s(wt_s[j]),.cout(wt_c[j])
        );
    end endgenerate

    ysyx_040066_walloc_33bits walloc129(
        .src_in(sw_group[4289:4257]),.cin(wt_cout[128]),
        .cout_group(),.s(wt_s[129]),.cout()
    );

    reg is_long;
    reg is_w_native;
    reg [129:0] wt_c_native;
    reg [129:0] wt_s_native;
    reg [1:0] part_cout_native;

    always @(posedge clk) if(~block) begin
        is_long<=ALUctr[0]||ALUctr[1];
        is_w_native<=is_w;
        wt_c_native<={wt_c,part_cout[30]};
        wt_s_native<=wt_s;
        part_cout_native[1]<=part_cout[32]||part_cout[31];
        part_cout_native[0]<=part_cout[32]^part_cout[31];
        //$display("display:wt_c=%h,wt_s%h",wt_c,wt_s);
    end

    wire [129:0] final_line;
    assign final_line=wt_c_native+wt_s_native+{128'b0,part_cout_native};
    assign result=is_long?final_line[127:64]:(is_w?{{32{final_line[31]}},final_line[31:0]}:final_line[63:0]);
    always @(*) begin
        //if(~clk) $display("final_line=%h",final_line);
    end
endmodule
