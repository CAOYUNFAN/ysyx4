module ysyx_220066_ID (
    input clk,rst,block,
    output ready,
    output reg valid,

    input ex_block,valid_in,
    input [31:0] instr,
    input [63:0] in_pc,
    input [63:0] src1_in,
    input [63:0] src2_in,
    input [63:0] csr_in,

    output reg [31:0] imm,
    output reg [63:0] src1_out,
    output reg [63:0] src2_out,
    output reg [4:0] rd,
    output reg [1:0] ALUBSrc,
    output reg ALUASrc,
    output reg [5:0] ALUctr,
    output reg [2:0] Branch,
    output reg MemWr,MemRd,
    output reg RegWr,
    output reg csr,ecall,mret,
    output reg [2:0] MemOp,
    output reg error,done,
    output reg [63:0] pc
);
    always @(posedge clk) begin
        if(rst) valid<=0;
        else if(block && valid) valid <= valid;
        else valid <= valid_in;
    end

    assign ready=~ex_block||~(block&&valid);
    wire [2:0] ExtOp;
    wire err_temp;

    wire csr_line;
    wire RegWr_line;
    wire ALUASrc_line;
    wire [1:0] ALUBSrc_line;
    wire [5:0] ALUctr_line;
    wire MemRd_line;
    wire [2:0] Branch_line;
    wire MemWr_line,MemRd_line;
    wire [2:0] MemOp_line;
    wire [31:0] imm_line;

    ysyx_220066_Decode decode(
        .OP(instr[6:0]),.Funct3(instr[14:12]),.Funct7(instr[31:25]),
        .ExtOp(ExtOp),.RegWr(RegWr_line),.ALUASrc(ALUASrc_line),.ALUBSrc(ALUBSrc_line),.ALUctr_out(ALUctr_line),.MemRd(MemRd_line),
        .Branch(Branch_line),.MemWr(MemWr_line),.MemOp(MemOp_line),.csr(csr_line),.error(err_temp)
    );

    ysyx_220066_IMM ysyx_220066_imm(
        .instr(instr[31:7]),.ExtOp(ExtOp),.imm(imm_line)
    );

    always @(posedge clk) if(!block||!valid) begin
        done<=(instr==32'h0010_0073);
        ecall<=(instr==32'h0000_0073);
        mret<=(instr==32'h3020_0073);
        rd<=instr[11:7];
        pc<=in_pc;
        error<=err_temp||(csr_line&&instr[14:12]==3'b000&&(instr!=32'h0010_0073&&instr!=32'h0000_0073&&instr!=32'h3020_0073));
        src1_out<=src1_in;
        src2_out<=csr_line?csr_in:src2_in;
        csr<=csr_line;
        RegWr<=RegWr_line;
        ALUASrc<=ALUASrc_line;
        ALUBSrc<=ALUBSrc_line;
        ALUctr<=ALUctr_line;
        MemRd<=MemRd_line;
        Branch<=Branch_line;
        {MemWr,MemRd}<={MemWr_line,MemRd_line};
        MemOp<=MemOp_line;
        imm<=imm_line;
    end

    always @(*) begin
//        $display("Instr=%h,error=%h",instr,error);
    end

endmodule

module ysyx_220066_Decode (
    input [6:0] OP,
    input [2:0] Funct3,
    input [6:0] Funct7,
    output reg [2:0] ExtOp,
    output RegWr,
    output reg [1:0] ALUBSrc,
    output ALUASrc,
    output [5:0] ALUctr_out,
    output reg [2:0] Branch,
    output MemWr,MemRd,
    output [2:0] MemOp,
    output csr,
    output error
);
    assign MemOp=Funct3;
    assign MemWr=(OP[6:2]==5'b01000);
    assign MemRd=(OP[6:2]==5'b00000);
    assign RegWr=(OP[6:2]!=5'b11000&&OP[6:2]!=5'b01000);
    assign ALUASrc=(OP[6:2]==5'b00101||OP[6:2]==5'b11011||OP[6:2]==5'b11001);
    reg [3:0] ALUctr;reg err;
    assign ALUctr_out[5]=((OP[6:2]==5'b01110||OP[6:2]==5'b01100)&&Funct7[0]);
    assign ALUctr_out[4]=OP[3]&~OP[2];
    assign ALUctr_out[3:0]=ALUctr;
    assign csr=(OP[6:2]==5'b11100);
    always @(*)//ALUctr
    case(OP[6:2])//ExtOp:I=000,U=101,B=011,S=010,J=001
        5'b11100:begin ExtOp=3'b000;ALUBSrc=0;ALUctr=4'b1111;Branch=3'b000; case(Funct3)
            3'b000,//ecall,ebreak,mret
            3'b001,//csrrw
            3'b101,//csrrwi
            3'b010,//csrrs
            3'b110,//csrrsi
            3'b011,//csrrc
            3'b111: begin                                                  err=0; end//csrrci
           default: begin                                                  err=1; end 
        endcase end//csr
        5'b01101:begin ExtOp=3'b101;ALUBSrc=2;ALUctr=4'b1111;Branch=3'b000;err=0; end//lui
        5'b00101:begin ExtOp=3'b101;ALUBSrc=2;ALUctr=4'b0000;Branch=3'b000;err=0; end//auipc
        5'b11011:begin ExtOp=3'b001;ALUBSrc=1;ALUctr=4'b0000;Branch=3'b001;err=0; end//jal
        5'b11001:begin ExtOp=3'b000;ALUBSrc=1;ALUctr=4'b0000;Branch=3'b010; case(Funct3)
            3'b000:begin                                                   err=0; end//jalr
           default:begin                                                   err=1; end//ERROR
        endcase end
        5'b11000:begin ExtOp=3'b011;ALUBSrc=0;case(Funct3) 
            3'b000:begin                        ALUctr=4'b0010;Branch=3'b100;err=0; end//beq
            3'b001:begin                        ALUctr=4'b0010;Branch=3'b101;err=0; end//bne
            3'b100:begin                        ALUctr=4'b0010;Branch=3'b110;err=0; end//blt
            3'b101:begin                        ALUctr=4'b0010;Branch=3'b111;err=0; end//bge
            3'b110:begin                        ALUctr=4'b0011;Branch=3'b110;err=0; end//bltu
            3'b111:begin                        ALUctr=4'b0011;Branch=3'b111;err=0; end//bgeu
           default:begin                        ALUctr=4'b0000;Branch=3'b000;err=1; end//ERROR
        endcase end
        5'b00000:begin ExtOp=3'b000;ALUBSrc=2;ALUctr=4'b0000;Branch=3'b000; case(Funct3) 
            3'b000,//lb
            3'b001,//lh
            3'b010,//lw
            3'b011,//ld
            3'b100,//lbu
            3'b101,//lhu
            3'b110:begin                                                     err=0; end//lwu
           default:begin                                                     err=1; end//ERROR
        endcase end
        5'b01000:begin ExtOp=3'b010;ALUBSrc=2;ALUctr=4'b0000;Branch=3'b000; case(Funct3) 
            3'b000,//sb
            3'b001,//su
            3'b010,//sw
            3'b011:begin                                                     err=0; end//sd
           default:begin                                                     err=1; end//ERROR
        endcase end
        5'b00100:begin //addi.. 
            ExtOp=3'b000;ALUBSrc=2;ALUctr[2:0]=Funct3;Branch=3'b000;
            ALUctr[3]=Funct7[5]&&(Funct3==3'b101);
            err=(Funct3==3'b001&&Funct7[6:1]!=6'b000000)||(Funct3==3'b101&&(Funct7[6:1]!=6'b000000&&Funct7[6:1]!=6'b010000)); 
        end
        5'b00110:begin //addiw..
            ExtOp=3'b000;ALUBSrc=2;ALUctr[2:0]=Funct3;Branch=3'b000;
            ALUctr[3]=Funct7[5]&&(Funct3==3'b101);
            err=(Funct3!=3'b000)&&(Funct3!=3'b001||Funct7!=7'b0000000)&&(Funct3!=3'b101||(Funct7!=7'b0000000&&Funct7!=7'b0100000)); 
        end
        5'b01100:begin //add..
            ExtOp=3'b000;ALUBSrc=0;ALUctr[2:0]=Funct3;Branch=3'b000;
            ALUctr[3]=Funct7[5];
            err=(Funct7!=7'b0000000&&Funct7!=7'b0100000&&Funct7!=7'b0000001);
        end
        5'b01110:begin //addw..
            ExtOp=3'b000;ALUBSrc=0;ALUctr[2:0]=Funct3;Branch=3'b000;
            ALUctr[3]=Funct7[5];
            err=(Funct7!=7'b0000000&&Funct7!=7'b0100000&&!(Funct3==3'b000||Funct3==3'b001||Funct3==3'b101))&&(Funct7!=7'b0000001||Funct3==3'b001||Funct3==3'b010||Funct3==3'b011);
        end
        default :begin ExtOp=3'b000;ALUBSrc=0;ALUctr=4'b0000;Branch=3'b000;err=1; end//ERROR
    endcase

    assign error=err||!(OP[1:0]==2'b11);

    always @(*) begin
//        $display("Funct7=%h,err=%h,error=%h",Funct7,err,error);
//        $display("OP=%b,done=%b",OP,done);
    end

endmodule

module ysyx_220066_IMM (
    input [31:7] instr,
    input [2:0] ExtOp,
    output [31:0] imm
);//ExtOp:I=000,U=101,B=011,S=010,J=001
    assign imm[31]={instr[31]};
    assign imm[30:20]=ExtOp[2]?instr[30:20]:{11{instr[31]}};
    assign imm[19:12]=(~ExtOp[1]&ExtOp[0])?instr[19:12]:{8{instr[31]}};
    assign imm[11]   =ExtOp[2]?1'b0://U
                      ~ExtOp[0]?instr[31]://IS
                      ExtOp[1] ?instr[7] :instr[20];//B-J
    assign imm[10: 5]=ExtOp[2] ?{6{1'b0}}:instr[30:25];
    assign imm[ 4: 1]=ExtOp[2] ?{4{1'b0}}:
                      ExtOp[1] ?instr[11:8]:instr[24:21];
    assign imm[ 0]   =ExtOp[0] ?1'b0://BUJ
                      ExtOp[1] ?instr[7]:instr[20];//S-B
endmodule
