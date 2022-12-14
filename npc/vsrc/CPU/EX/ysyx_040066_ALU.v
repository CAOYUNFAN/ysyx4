module ysyx_040066_ALU(
    input [63:0] data_input,
    input [63:0] datab_input,
    input [4:0] aluctr,
    output zero,
    output [2:0] add_lowbit,
    output reg [63:0] result
    );
    wire ALctr,SUBctr,Wctr,CF,SF,OF;
    wire [63:0] Add_result;
    ysyx_040066_ALU_decode alu_decode(aluctr[4:3],aluctr[1],ALctr,SUBctr,Wctr);
    wire [31:0] data_sll;
    assign data_sll=(data_input[31:0]<<datab_input[4:0]);
    wire [31:0] data_srl;
    assign data_srl=(data_input[31:0]>>datab_input[4:0]);
    wire [31:0] data_sra;
    assign data_sra=$signed($signed(data_input[31:0])>>>$signed(datab_input[4:0]));

    ysyx_040066_Adder adder(data_input,datab_input,SUBctr,Add_result,CF,SF,OF);
    always @(*)
    case (aluctr[2:0])
        3'o0: result={Wctr?{32{Add_result[31]}}:Add_result[63:32],Add_result[31:0]};
        3'o1: result=Wctr?{{32{data_sll[31]}},data_sll}:data_input<<datab_input[5:0];
        3'o2: result={{63{1'b0}},OF^SF};
        3'o3: result={{63{1'b0}},CF};
        3'o4: result=data_input^datab_input;
        3'o5: result=~Wctr?
                    (ALctr?($signed(($signed(data_input))>>>datab_input[5:0])):data_input>>datab_input[5:0]):
                    (ALctr?{{32{data_sra[31]}},data_sra}:{{32{data_srl[31]}},data_srl});
        3'o6: result=data_input|datab_input;
        3'o7: result=({64{aluctr[3]}}|data_input)&datab_input;
    endcase

    assign add_lowbit=Add_result[2:0];
    assign zero=~|(data_input^datab_input);

    always @(*) begin
//        $display("ALU:data_input=%x,datab_input=%x,Add_result=%x,result=%x,aluctr=%b,zero=%b",data_input,datab_input,Add_result,result,aluctr,zero);
    end

endmodule

module ysyx_040066_Adder(
    input [63:0] x,
    input [63:0] y,
    input SUBctr,
    output reg [63:0] result,
    output reg CF,SF,OF
    );
    reg [63:0] y_;
    reg Ctemp,Cout;
    always @(*) begin
        y_=SUBctr?~y:y;
        {Ctemp,result[62:0]}={1'b0,x[62:0]}+{1'b0,y_[62:0]}+{{63{1'b0}},SUBctr};
        {Cout,result[63]}={1'b0,x[63]}+{1'b0,y_[63]}+{1'b0,Ctemp};
        SF=result[63];
        OF=Cout^Ctemp;
        CF=SUBctr^Cout;
    end
endmodule

module ysyx_040066_ALU_decode(
    input [4:3] ALUctr,
    input ALUctr_1,
    output ALctr,SUBctr,Wctr
    );
    assign SUBctr=ALUctr[3]|ALUctr_1;
    assign ALctr=ALUctr[3];
    assign Wctr=ALUctr[4];
endmodule
