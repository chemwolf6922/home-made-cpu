module MUX2 #(
    parameter BITS=32
) (
    input wire addr,
    input wire [BITS-1:0] in0,
    input wire [BITS-1:0] in1,
    output wire [BITS-1:0] out
);
    assign out[BITS-1:0] = addr?in1[BITS-1:0]:in0[BITS-1:0];
endmodule

module MUX4 #(
    parameter BITS=32
) (
    input wire [1:0] addr,
    input wire [BITS-1:0] in0,
    input wire [BITS-1:0] in1,
    input wire [BITS-1:0] in2,
    input wire [BITS-1:0] in3,
    output wire [BITS-1:0] out
);
    wire [BITS-1:0] sub0;
    wire [BITS-1:0] sub1;
    MUX2 #(.BITS(BITS)) subMux0 (.in0(in0), .in1(in1), .addr(addr[0]), .out(sub0));
    MUX2 #(.BITS(BITS)) subMux1 (.in0(in2), .in1(in3), .addr(addr[0]), .out(sub1));
    MUX2 #(.BITS(BITS)) subMux2 (.in0(sub0), .in1(sub1), .addr(addr[1]), .out(out));
endmodule

module MUX8 #(
    parameter BITS=32
) (
    input wire [2:0] addr,
    input wire [BITS-1:0] in0,
    input wire [BITS-1:0] in1,
    input wire [BITS-1:0] in2,
    input wire [BITS-1:0] in3,
    input wire [BITS-1:0] in4,
    input wire [BITS-1:0] in5,
    input wire [BITS-1:0] in6,
    input wire [BITS-1:0] in7,
    output wire [BITS-1:0] out
);
    wire [BITS-1:0] sub0;
    wire [BITS-1:0] sub1;
    MUX4 #(.BITS(BITS)) subMux0 (.in0(in0), .in1(in1), .in2(in2), .in3(in3), .addr(addr[1:0]), .out(sub0));
    MUX4 #(.BITS(BITS)) subMux1 (.in0(in4), .in1(in5), .in2(in6), .in3(in7), .addr(addr[1:0]), .out(sub1));
    MUX2 #(.BITS(BITS)) subMux2 (.in0(sub0), .in1(sub1), .addr(addr[2]), .out(out));
endmodule

module MUX16 #(
    parameter BITS=32
) (
    input wire [3:0] addr,
    input wire [BITS-1:0] in0,
    input wire [BITS-1:0] in1,
    input wire [BITS-1:0] in2,
    input wire [BITS-1:0] in3,
    input wire [BITS-1:0] in4,
    input wire [BITS-1:0] in5,
    input wire [BITS-1:0] in6,
    input wire [BITS-1:0] in7,
    input wire [BITS-1:0] in8,
    input wire [BITS-1:0] in9,
    input wire [BITS-1:0] in10,
    input wire [BITS-1:0] in11,
    input wire [BITS-1:0] in12,
    input wire [BITS-1:0] in13,
    input wire [BITS-1:0] in14,
    input wire [BITS-1:0] in15,
    output wire [BITS-1:0] out
);
    wire [BITS-1:0] sub0;
    wire [BITS-1:0] sub1;
    MUX8 #(.BITS(BITS)) subMux0 (
        .in0(in0), 
        .in1(in1), 
        .in2(in2), 
        .in3(in3), 
        .in4(in4), 
        .in5(in5), 
        .in6(in6), 
        .in7(in7), 
        .addr(addr[2:0]), 
        .out(sub0)
    );
    MUX8 #(.BITS(BITS)) subMux1 (
        .in0(in8), 
        .in1(in9), 
        .in2(in10), 
        .in3(in11), 
        .in4(in12), 
        .in5(in13), 
        .in6(in14), 
        .in7(in15), 
        .addr(addr[2:0]), 
        .out(sub1)
    );
    MUX2 #(.BITS(BITS)) subMux2 (.in0(sub0), .in1(sub1), .addr(addr[3]), .out(out));
endmodule

module DEMUX2 #(
    parameter BITS=32
) (
    input wire addr,
    input wire [BITS-1:0] in,
    output wire [BITS-1:0] out0,
    output wire [BITS-1:0] out1
);
    assign out0 = addr?{(BITS){1'b0}}:in;
    assign out1 = addr?in:{(BITS){1'b0}};
endmodule

module DEMUX4 #(
    parameter BITS=32
) (
    input wire [1:0] addr,
    input wire [BITS-1:0] in,
    output wire [BITS-1:0] out0,
    output wire [BITS-1:0] out1,
    output wire [BITS-1:0] out2,
    output wire [BITS-1:0] out3
);
    wire [BITS-1:0] sub0;
    wire [BITS-1:0] sub1;
    DEMUX2 #(.BITS(BITS)) subDemux0 (
        .addr(addr[0]),
        .in(sub0),
        .out0(out0),
        .out1(out1)
    );
    DEMUX2 #(.BITS(BITS)) subDemux1 (
        .addr(addr[0]),
        .in(sub1),
        .out0(out2),
        .out1(out3)
    );
    DEMUX2 #(.BITS(BITS)) subDemux2 (
        .addr(addr[1]),
        .in(in),
        .out0(sub0),
        .out1(sub1)
    );
endmodule

module DEMUX8 #(
    parameter BITS=32
) (
    input wire [2:0] addr,
    input wire [BITS-1:0] in,
    output wire [BITS-1:0] out0,
    output wire [BITS-1:0] out1,
    output wire [BITS-1:0] out2,
    output wire [BITS-1:0] out3,
    output wire [BITS-1:0] out4,
    output wire [BITS-1:0] out5,
    output wire [BITS-1:0] out6,
    output wire [BITS-1:0] out7
);
    wire [BITS-1:0] sub0;
    wire [BITS-1:0] sub1;
    DEMUX4 #(.BITS(BITS)) subDemux0 (
        .addr(addr[1:0]),
        .in(sub0),
        .out0(out0),
        .out1(out1),
        .out2(out2),
        .out3(out3)
    );
    DEMUX4 #(.BITS(BITS)) subDemux1 (
        .addr(addr[1:0]),
        .in(sub1),
        .out0(out4),
        .out1(out5),
        .out2(out6),
        .out3(out7)
    );
    DEMUX2 #(.BITS(BITS)) subDemux2 (
        .addr(addr[2]),
        .in(in),
        .out0(sub0),
        .out1(sub1)
    );
endmodule

module DEMUX16 #(
    parameter BITS=32
) (
    input wire [3:0] addr,
    input wire [BITS-1:0] in,
    output wire [BITS-1:0] out0,
    output wire [BITS-1:0] out1,
    output wire [BITS-1:0] out2,
    output wire [BITS-1:0] out3,
    output wire [BITS-1:0] out4,
    output wire [BITS-1:0] out5,
    output wire [BITS-1:0] out6,
    output wire [BITS-1:0] out7,
    output wire [BITS-1:0] out8,
    output wire [BITS-1:0] out9,
    output wire [BITS-1:0] out10,
    output wire [BITS-1:0] out11,
    output wire [BITS-1:0] out12,
    output wire [BITS-1:0] out13,
    output wire [BITS-1:0] out14,
    output wire [BITS-1:0] out15
);
    wire [BITS-1:0] sub0;
    wire [BITS-1:0] sub1;
    DEMUX8 #(.BITS(BITS)) subDemux0 (
        .addr(addr[2:0]),
        .in(sub0),
        .out0(out0),
        .out1(out1),
        .out2(out2),
        .out3(out3),
        .out4(out4),
        .out5(out5),
        .out6(out6),
        .out7(out7)
    );
    DEMUX8 #(.BITS(BITS)) subDemux1 (
        .addr(addr[2:0]),
        .in(sub1),
        .out0(out8),
        .out1(out9),
        .out2(out10),
        .out3(out11),
        .out4(out12),
        .out5(out13),
        .out6(out14),
        .out7(out15)
    );
    DEMUX2 #(.BITS(BITS)) subDemux2 (
        .addr(addr[3]),
        .in(in),
        .out0(sub0),
        .out1(sub1)
    );
endmodule

