module ysyx_220066_walloc_33bits(
    input [32:0] src_in,
    /* verilator lint_off UNOPTFLAT */
    input [29:0] cin,

    /* verilator lint_off UNOPTFLAT */
    output [29:0] cout_group,
    output cout,s
);
    //first
    wire [10:0] first_s;
    ysyx_220066_csa csa00(.src(src_in[32:30]),.cout(cout_group[10]),.s(first_s[10]));
    ysyx_220066_csa csa01(.src(src_in[29:27]),.cout(cout_group[ 9]),.s(first_s[ 9]));
    ysyx_220066_csa csa02(.src(src_in[26:24]),.cout(cout_group[ 8]),.s(first_s[ 8]));
    ysyx_220066_csa csa03(.src(src_in[23:21]),.cout(cout_group[ 7]),.s(first_s[ 7]));
    ysyx_220066_csa csa04(.src(src_in[20:18]),.cout(cout_group[ 6]),.s(first_s[ 6]));
    ysyx_220066_csa csa05(.src(src_in[17:15]),.cout(cout_group[ 5]),.s(first_s[ 5]));
    ysyx_220066_csa csa06(.src(src_in[14:12]),.cout(cout_group[ 4]),.s(first_s[ 4]));
    ysyx_220066_csa csa07(.src(src_in[11: 9]),.cout(cout_group[ 3]),.s(first_s[ 3]));
    ysyx_220066_csa csa08(.src(src_in[ 8: 6]),.cout(cout_group[ 2]),.s(first_s[ 2]));
    ysyx_220066_csa csa09(.src(src_in[ 5: 3]),.cout(cout_group[ 1]),.s(first_s[ 1]));
    ysyx_220066_csa csa0a(.src(src_in[ 2: 0]),.cout(cout_group[ 0]),.s(first_s[ 0]));

    //second
    wire [6:0] second_s;
    ysyx_220066_csa csa10(.src(first_s[10: 8]),.cout(cout_group[17]),.s(second_s[6]));
    ysyx_220066_csa csa11(.src(first_s[ 7: 5]),.cout(cout_group[16]),.s(second_s[5]));
    ysyx_220066_csa csa12(.src(first_s[ 4: 2]),.cout(cout_group[15]),.s(second_s[4]));
    ysyx_220066_csa csa13(.src({first_s[1:0],cin[10]}),.cout(cout_group[14]),.s(second_s[3]));
    ysyx_220066_csa csa14(.src(cin[ 9: 7]),.cout(cout_group[13]),.s(second_s[2]));
    ysyx_220066_csa csa15(.src(cin[ 6: 4]),.cout(cout_group[12]),.s(second_s[1]));
    ysyx_220066_csa csa16(.src(cin[ 3: 1]),.cout(cout_group[11]),.s(second_s[0]));

    //third
    wire [4:0] third_s;
    ysyx_220066_csa csa20(.src(second_s[6:4]),.cout(cout_group[22]),.s(third_s[4]));
    ysyx_220066_csa csa21(.src(second_s[3:1]),.cout(cout_group[21]),.s(third_s[3]));
    ysyx_220066_csa csa22(.src({second_s[0],cin[0],cin[17]}),.cout(cout_group[20]),.s(third_s[2]));
    ysyx_220066_csa csa23(.src(cin[16:14]),.cout(cout_group[19]),.s(third_s[1]));
    ysyx_220066_csa csa24(.src(cin[13:11]),.cout(cout_group[18]),.s(third_s[0]));

    //fourth
    wire [2:0] fourth_s;
    ysyx_220066_csa csa30(.src(third_s[4:2]),.cout(cout_group[25]),.s(fourth_s[2]));
    ysyx_220066_csa csa31(.src({third_s[1:0],cin[22]}),.cout(cout_group[24]),.s(fourth_s[1]));
    ysyx_220066_csa csa32(.src(cin[21:19]),.cout(cout_group[23]),.s(fourth_s[0]));

    //fifth
    wire [1:0] fifth_s;
    ysyx_220066_csa csa40(.src(fourth_s[2:0]),.cout(cout_group[27]),.s(fifth_s[1]));
    ysyx_220066_csa csa41(.src({cin[18],cin[25:24]}),.cout(cout_group[26]),.s(fifth_s[0]));

    //sixth
    wire sixth_s;
    ysyx_220066_csa csa50(.src({fifth_s,cin[23]}),.cout(cout_group[28]),.s(sixth_s));

    //seventh
    wire seventh_s;
    ysyx_220066_csa csa60(.src({sixth_s,cin[27:26]}),.cout(cout_group[29]),.s(seventh_s));

    //final
    ysyx_220066_csa csa70(.src({seventh_s,cin[28],cin[29]}),.cout(cout),.s(s));
endmodule

module ysyx_220066_csa(
    /* verilator lint_off UNOPTFLAT */
    input [2:0] src,
    output cout,s
);
    assign s=src[0]^src[1]^src[2];
    assign cout=(src[0]&&src[1])||(src[0]&&src[2])||(src[1]&&src[2]);
endmodule