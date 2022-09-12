module SysMux (
    input wire [1:0] mode,
    input wire immEn,
    
    // reg
    output wire [31:0] regIn1,
    output wire [31:0] regIn2,
    input wire [31:0] regOut1,
    input wire [31:0] regOut2,
    input wire [31:0] regPc,
    output wire regPush,
    // fetch
    output wire [31:0] fetchIn,
    input wire [31:0] fetchImm,
    output wire fetchPush,
    // alu
    input wire [31:0] aluOut1,
    input wire [31:0] aluOut2,
    output wire [31:0] aluIn1,
    output wire [31:0] aluIn2,
    output wire [31:0] aluPc,
    input wire aluPush,
    // mem
    input wire [31:0] memQ,
    output wire [31:0] memAddr,
    output wire [31:0] memData,
    input wire memPush
);
    wire [31:0] imm1MuxOut;
    wire [31:0] imm2MuxOut;
    
    

    MUX2 #(.BITS(32)) imm1Mux(
        .addr(immEn),
        .in0(regOut1),
        .in1(fetchImm),
        .out(imm1MuxOut)
    );

    MUX2 #(.BITS(32)) imm2Mux(
        .addr(immEn),
        .in0(regOut1),
        .in1(fetchImm),
        .out(imm2MuxOut)
    );

    MUX4 #(.BITS(32)) memAddrMux(
        .addr(mode),
        .in0(32'b0),
        .in1(imm2MuxOut),
        .in2(regPc),
        .in3(32'b0),
        .out(memAddr)
    );

    // assign memData = regOut2;
    MUX4 #(.BITS(32)) memDataMux(
        .addr(mode),
        .in0(32'b0),
        .in1(regOut2),
        .in2(32'b0),
        .in3(32'b0),
        .out(memData)
    );

    // assign  fetchIn = memQ;
    MUX4 #(.BITS(32)) fetchInMux(
        .addr(mode),
        .in0(32'b0),
        .in1(32'b0),
        .in2(memQ),
        .in3(32'b0),
        .out(fetchIn)
    );

    MUX4 #(.BITS(1)) fetchPushMux(
        .addr(mode),
        .in0(1'b0),
        .in1(1'b0),
        .in2(memPush),
        .in3(1'b0),
        .out(fetchPush)
    );

    // assign aluIn1 = imm1MuxOut;
    MUX4 #(.BITS(32)) aluIn1Mux(
        .addr(mode),
        .in0(imm1MuxOut),
        .in1(32'b0),
        .in2(32'b0),
        .in3(32'b0),
        .out(aluIn1)
    );

    // assign aluIn2 = regOut2;
    MUX4 #(.BITS(32)) aluIn2Mux(
        .addr(mode),
        .in0(regOut2),
        .in1(32'b0),
        .in2(32'b0),
        .in3(32'b0),
        .out(aluIn2)
    );
    
    // assign aluPc = regPc;
    MUX4 #(.BITS(32)) aluPcMux(
        .addr(mode),
        .in0(regPc),
        .in1(32'b0),
        .in2(32'b0),
        .in3(32'b0),
        .out(aluPc)
    );

    MUX4 #(.BITS(1)) regPushMux(
        .addr(mode),
        .in0(aluPush),
        .in1(memPush),
        .in2(1'b0),
        .in3(1'b0),
        .out(regPush)
    );

    MUX4 #(.BITS(32)) regIn1Mux(
        .addr(mode),
        .in0(aluOut1),
        .in1(memQ),
        .in2(32'b0),
        .in3(32'b0),
        .out(regIn1)
    );
    
    MUX4 #(.BITS(32)) regIn2Mux(
        .addr(mode),
        .in0(aluOut2),
        .in1(32'b0),
        .in2(32'b0),
        .in3(32'b0),
        .out(regIn2)
    );
    
endmodule