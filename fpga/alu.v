module ALU (
    // clock
    input wire [0:0] clk,
    input wire [0:0] nrst,
    // sequence control
    input wire [0:0] enable,
    // data input
    input wire [31:0] in1,
    input wire [31:0] in2,
    input wire [31:0] pc,
    // function control ports
    input wire [2:0] opCode,
    input wire sub,
    input wire cjmp,
    input wire crjmp,
    // data output
    output reg [31:0] out1,
    output reg [31:0] out2,
    output wire [0:0] pushResult,
    // sequence control
    output reg [0:0] next
);  
    wire [31:0] ADDIn1;
    wire [31:0] ADDIn2;
    wire ADDCIn;
    wire [31:0] ADDOut;
    wire [31:0] ADDCOut;
    ADDModule ADDInstance(.a(ADDIn1), .b(ADDIn2), .cIn(ADDCIn), .o(ADDOut), .cOut(ADDCOut));

    wire [31:0] LSIn;
    wire [31:0] LSBits;
    wire [31:0] LSOutL;
    wire [31:0] LSOutH;
    LSModule LSInstance(.in(LSIn), .bits(LSBits), .outL(LSOutL), .outH(LSOutH));

    wire [31:0] CLZIn;
    wire [31:0] CLZOut;
    CLZModule CLZInstance(.in(CLZIn), .out(CLZOut));

    wire [31:0] ANDIn1;
    wire [31:0] ANDIn2;
    wire [31:0] ANDOut;
    ANDModule ANDInstance(.in1(ANDIn1), .in2(ANDIn2), .out(ANDOut));

    wire [31:0] ORIn1;
    wire [31:0] ORIn2;
    wire [31:0] OROut;
    ORModule ORInstance(.in1(ORIn1), .in2(ORIn2), .out(OROut));

    wire [31:0] XORIn1;
    wire [31:0] XORIn2;
    wire [31:0] XOROut;
    XORModule XORInstance(.in1(XORIn1), .in2(XORIn2), .out(XOROut));

    wire [31:0] NOTIn;
    wire [31:0] NOTOut;
    NOTModule NOTInstance(.in(NOTIn), .out(NOTOut));

    wire [31:0] EQIn1;
    wire [31:0] EQIn2;
    wire [31:0] EQOut;
    EQModule EQInstance(.in1(EQIn1), .in2(EQIn2), .out(EQOut));

    assign ADDCIn = sub;
    assign ADDIn1 = sub?NOTOut:
                    cjmp&(~EQOut[0])?32'b1:
                    in1;
    assign ADDIn2 = cjmp&(EQOut[0]&(~crjmp))?32'b0:
                    cjmp&(~(EQOut[0]&(~cjmp)))?pc:
                    in2;
    assign EQIn1 = cjmp?32'b0:in1;

    assign CLZIn = in1;
    assign LSBits = in1;
    assign ANDIn1 = in1;
    assign ORIn1 = in1;
    assign NOTIn = in1;
    assign XORIn1 = in1;

    assign LSIn = in2;
    assign ANDIn2 = in2;
    assign ORIn2 = in2;
    assign XORIn2 = in2;
    assign EQIn2 = in2;

    wire [31:0] out1Wire;
    MUX8 #(.BITS(32)) out1Mux (
        .addr(opCode),
        .in0(ADDOut),
        .in1(CLZOut),
        .in2(LSOutL),
        .in3(ANDOut),
        .in4(OROut),
        .in5(NOTOut),
        .in6(XOROut),
        .in7(EQOut),
        .out(out1Wire)
    );

    wire [31:0] out2Wire;
    MUX8 #(.BITS(32)) out2Mux (
        .addr(opCode),
        .in0(ADDCOut),
        .in1(32'b0),
        .in2(LSOutH),
        .in3(32'b0),
        .in4(32'b0),
        .in5(32'b0),
        .in6(32'b0),
        .in7(32'b0),
        .out(out2Wire)
    );

    reg [1:0] steps;
    reg pushMusk;
    assign pushResult = steps[1] & pushMusk;
    initial begin
        steps = 2'b0;
        out1 = 32'b0;
        out2 = 32'b0;
        next = 1'b0;
        pushMusk = 1'b0;
    end
    
    // steps & out1 out2
    always @(posedge clk or negedge nrst) begin
        if(~nrst) begin
            steps <= 2'b0;
            out1 <= 32'b0;
            out2 <= 32'b0;
        end
        else if(enable) begin
            steps <= 2'b1;
            out1 <= out1Wire;
            out2 <= out2Wire;
        end
        else begin
            steps[1] <= steps[0];
            steps[0] <= 1'b0;
        end
    end
    // pushMusk
    always @(negedge clk or negedge nrst) begin
        if(~nrst) begin
            pushMusk = 1'b0;
        end
        else if(steps[0]) begin
            pushMusk = 1'b1;
        end
        else begin
            pushMusk = 1'b0;
        end
    end
    // next
    always @(negedge clk or negedge nrst) begin
        if(~nrst) begin
            next = 1'b0;
        end
        else if(steps[1]) begin
            next = 1'b1;
        end
        else begin
            next = 1'b0;
        end
    end

endmodule

module ADDModule (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire cIn,
    output wire [31:0] o,
    output wire [31:0] cOut
);

    wire [32:0] c;

    assign c[0] = cIn;

    assign o[31:0] = a[31:0]^b[31:0]^c[31:0];
    assign c[32:1] = (a[31:0]&(b[31:0]|c[31:0]))|(b[31:0]&c[31:0]);

    assign cOut[0] = c[32];
    assign cOut[31:1] = 31'b0;

endmodule

module LSModule (
    input wire [31:0] bits,
    input wire [31:0] in,
    output wire [31:0] outL,
    output wire [31:0] outH
);
    
    wire [32:0] s1;
    wire [34:0] s2;
    wire [38:0] s4;
    wire [46:0] s8;
    wire [62:0] s16;

    assign s1[32] = bits[0]?in[31]:1'd0;
    assign s1[31:1] = bits[0]?in[30:0]:in[31:1];
    assign s1[0] = bits[0]?1'd0:in[0];

    assign s2[34:33] = bits[1]?s1[32:31]:2'd0;
    assign s2[32:2] = bits[1]?s1[30:0]:s1[32:2];
    assign s2[1:0] = bits[1]?2'd0:s1[1:0];

    assign s4[38:35] = bits[2]?s2[34:31]:4'd0;
    assign s4[34:4] = bits[2]?s2[30:0]:s2[34:4];
    assign s4[3:0] = bits[2]?4'd0:s2[3:0];

    assign s8[46:39] = bits[3]?s4[38:31]:8'd0;
    assign s8[38:8] = bits[3]?s4[30:0]:s4[38:8];
    assign s8[7:0] = bits[3]?8'd0:s4[7:0];

    assign s16[62:47] = bits[4]?s8[46:31]:16'd0;
    assign s16[46:16] = bits[4]?s8[30:0]:s8[46:16];
    assign s16[15:0] = bits[4]?16'd0:s8[15:0];

    assign outH[31] = 1'd0;
    assign outH[30:0] = s16[62:32];
    assign outL[31:0] = s16[31:0];

endmodule

module CLZModule (
    input wire [31:0] in,
    output wire [31:0] out
);
    wire [15:0] h16;
    wire [7:0] h8;
    wire [3:0] h4;
    wire [1:0] h2;

    assign out[5] = in[31:0]==32'b0;
    assign out[4] = (in[31:16]==16'b0)&(in[15:0]!=16'b0);
    assign h16 = out[4]?in[15:0]:in[31:16];
    assign out[3] = (h16[15:8]==8'b0)&(in[7:0]!=8'b0);
    assign h8 = out[3]?h16[7:0]:h16[15:8];
    assign out[2] = (h8[7:4]==4'b0)&(h8[3:0]!=4'b0);
    assign h4 = out[2]?h8[3:0]:h8[7:4];
    assign out[1] = (h4[3:2]==2'b0)&(h4[1:0]!=2'b0);
    assign h2 = out[1]?h4[1:0]:h4[3:2];
    assign out[0] = (~h2[1])&(h2[0]);

    assign out[31:6] = 26'b0;

endmodule

module ANDModule (
    input wire [31:0] in1,
    input wire [31:0] in2,
    output wire [31:0] out
);
    assign out[31:0] = in1[31:0]&in2[31:0];
endmodule

module ORModule (
    input wire [31:0] in1,
    input wire [31:0] in2,
    output wire [31:0] out
);
    assign out[31:0] = in1[31:0]|in2[31:0];
endmodule

module NOTModule (
    input wire [31:0] in,
    output wire [31:0] out
);
    assign out[31:0] = ~in[31:0];
endmodule

module XORModule (
    input wire [31:0] in1,
    input wire [31:0] in2,
    output wire [31:0] out
);
    assign out[31:0] = in1[31:0]^in2[31:0];
endmodule

module EQModule (
    input wire [31:0] in1,
    input wire [31:0] in2,
    output wire [31:0] out
);
    assign out[31:1] = 31'b0;
    assign out[0] = in1[31:0] == in2[31:0];
endmodule
