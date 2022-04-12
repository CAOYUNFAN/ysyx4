module ysyx_220066_ALU(
    input [63:0] data_input,
    input [63:0] datab_input,
    input [4:0] aluctr,
    output zero,
    output reg [63:0] result
    );
    wire ALctr,SUBctr,SIGctr,Wctr,CF,SF,OF,Cout;
    wire [63:0] Add_result;
    wire [63:0] shift_result;
    ysyx_220066_ALU_decode ysyx_220066_alu_decode(aluctr[4:3],ALctr,SUBctr,SIGctr,Wctr);
    wire [63:0] data;
    assign data[31:0]=data_input[31:0];
    assign data[63:32]=Wctr?{32{data_input[31]}}:data_input[63:32];
    wire [63:0] dataa;
    assign dataa[31:0]=data_input[31:0];
    assign dataa[63:32]=Wctr?{32{data_input[31]&ALctr}}:data_input[63:32];
    wire [63:0] datab;
    assign datab[31:0]=datab_input[31:0];
    assign datab[63:32]=Wctr?{32{datab_input[31]}}:datab_input[63:32];
    ysyx_220066_Adder ysyx_220066_adder(data,datab,SUBctr,Add_result,CF,zero,SF,OF,Cout);
    always @(*)
    case (aluctr[2:0])
        3'o0: result=Add_result;
        3'o1: result=data<<datab[5:0];
        3'o2: begin 
                  result[0]=~SIGctr?(CF)
                                   :(OF^SF);
                  result[63:1]={63{1'b0}};
              end
        3'o3: result=datab;
        3'o4: result=data^datab;
        3'o5: result=ALctr?($signed(($signed(data_a))>>>datab[5:0])):data_a>>datab[5:0];
        3'o6: result=data|datab;
        3'o7: result=data&datab;
    endcase
endmodule

module ysyx_220066_Adder(
    input [63:0] x,
    input [63:0] y,
    input SUBctr,
    output reg [63:0] result,
    output reg CF,ZF,SF,OF,Cout
    );
    reg [63:0] y_;
    reg Ctemp;
    always @(*) begin
        y_=SUBctr?~y:y;
        {Ctemp,result[62:0]}={1'b0,x[62:0]}+{1'b0,y_[62:0]}+{{63{1'b0}},SUBctr};
        {Cout,result[63]}={1'b0,x[63]}+{1'b0,y_[63]}+{1'b0,Ctemp};
        SF=result[63];
        OF=Cout^Ctemp;
        ZF=~|result;
        CF=SUBctr^Cout;
    end
endmodule

module ysyx_220066_ALU_decode(
    input [4:3] ALUctr,
    output ALctr,SUBctr,SIGctr,Wctr
    );
    assign SUBctr=ALUctr[3];
    assign ALctr=ALUctr[3];
    assign SIGctr=ALUctr[3];
    assign Wctr=ALUctr[4];
endmodule
